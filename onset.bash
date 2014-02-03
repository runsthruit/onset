#! /bin/bash

function __onset ()
#
#
#
{

declare {ERR,FNCS,FNC,SHOPT_HISTORY_BAK}=

SHOPT_HISTORY_BAK="$( shopt -p -o history )"
shopt -u -o history

function end ()
#
#
#
{
	declare ERR="${1}"
	__onset_f_trap "${ERR}" EXIT
}

function out ()
#
#
#
{ printf "${@:-}"; }

function err ()
#
#
#
{ printf "${@:-}" 1>&2; }

function msg ()
#
#
#
{
	declare {TAG,FRM,MSG}=
	TAG="${1:-}"; shift
	FRM="${1:-}"; shift
	MSG=( "${@:-}" )
	printf "${__onset_v_base:-${BASH_SOURCE[0]##*/}}${TAG} ${FRM}" "${MSG[@]}" 1>&2
}

function catmsg ()
#
#
#
{
	declare {TAG,FRM,MSGS}=
	TAG="${1}"; shift
	FRM="${1}"; shift
	MSGS=( "${@:--}" )
	cat "${MSGS[@]}" |
	while IFS="${NLN}" read -r MSG
	do
		msg "${TAG}" "${FRM}" "${MSG}"
	done #\
	#	< <( cat "${MSGS[@]}" )
}

function __onset_f_log ()
{
        [ -r /dev/fd/6 ] || exec 6>&0
        [ -w /dev/fd/7 ] || exec 7>&1
        [ -w /dev/fd/8 ] || exec 8>&2
        exec 1> >( tee "${__onset_v_tdir_log}" )
}

function __onset_f_trap_flag ()
#
#
#
{
	declare FLG="${1}"
	eval '[ "${__onset_v_flg_'"${FLG}"'}" -ne 0 -a "${__onset_v_allow_'"${FLG}"'}" == "0" ] || return 0'
	eval 'end "${__onset_v_err_'"${FLG}"'}"'
}

function __onset_f_init_trap ()
#
#
#
{
	declare {FNC,SIG,TAG}=
	FNC=__onset_f_trap
	for SIG in ${__onset_v_sigs[*]:-EXIT}
	do
		TAG="$( echo "${SIG}" | tr "[:upper:]" "[:lower:]" )"
		eval "trap '${FNC} ${SIG}; echo \"{{{ ${SIG} }}}\" 1>&2' ${SIG}"
	done
}

function __onset_f_trap ()
#
#
#
{
	declare ERR="${?}"
	declare CMD="${BASH_COMMAND}"
	declare {SIG,I,CALL_{LIN,FNC,SRC}}=
	SIG="${1}"
	shift
	[[ "${SIG}" =~ ^[0-9]+$ ]] && { ERR="${SIG}"; SIG=ERROR; shift; } || :
	declare MSGS=()
	I=0
	[ "${ERR}" -eq 0 ] \
	|| {
	[ "${SIG}" == "ERROR" ] \
	&& {
		printf "\n" 1>&2
		IFS="${NLN}"
		MSGS=( $( printf "${__onset_v_errs[${ERR}]:-${@:-END:${ERR}}}\n" ) )
		IFS="${IFS_BAK}"
		msg - "%s\n" "${MSGS[@]}"
	} \
	|| {
		printf "\n" 1>&2
		msg - "%s { %s } [ %s ]\n" "${SIG}" "${CMD:-UNKNOWN}" "${ERR}"
		while :
		do
			CALL_SRC="$( caller ${I} || : )"
			[ -n "${CALL_SRC:-}" ] || break
			[[ "${CALL_SRC}" =~ ([0-9]+)[[:blank:]]+(.*) ]]
			CALL_LIN="${BASH_REMATCH[1]}"
			CALL_SRC="${BASH_REMATCH[2]}"
			[[ "${CALL_SRC}" =~ ([^[:blank:]]+)[[:blank:]]+(.*) ]]
			CALL_FNC="${BASH_REMATCH[1]}"
			CALL_SRC="${BASH_REMATCH[2]}"
			: $((I++))
			[ "end" != "${CALL_FNC}" ] || continue
			err "%s:%s:%s: ..\n" "${CALL_SRC#./}" "${CALL_FNC}" "${CALL_LIN}"
		done
	}
	}
	case "${SIG}" in
	( * ) {
		__onset_f_bail "${ERR}" "${SIG}"
	};;
	esac
}

function __onset_f_bail ()
#
#
#
{
	declare ERR="${1:-0}"
	declare SIG="${2:-EXIT}"
	trap - EXIT
	declare UNSET="
		trap - ${__onset_v_sigs[*]:-EXIT}
		unset end out {,cat}msg $(
			{
				compgen -A function | egrep -v "^(__onset|__onset_f_show_variables)\$";
				compgen -A variable | egrep -v "^__onset_v_.*_bak\$";
			} | grep ^__onset | sort -r | paste -sd" " -
		) || :
		${__onset_v_shopt_bak}
		${__onset_v_shellopt_bak}
		rm -rf "${__onset_v_tdir_sec}"*
		${__onset_v_traps_bak}
	"
	#echo "${UNSET}" | less
	eval "${UNSET}"
	trap -p 1>&2
	[[ $- == *i* ]] \
	&& {
		return ${ERR}
	} \
	|| {
		#echo exit ${ERR} 1>&2
		exit ${ERR}
	}
}

function __onset_f_dts_loc_now ()
#
#
#
{ date "+%Y-%m-%dT%H:%M:%S" ${@:+"${@}"}; }

function __onset_f_dts_utc_now ()
#
#
#
{ TZ=UTC date "+%Y-%m-%dT%H:%M:%SZ" ${@:+"${@}"}; }

function __onset_f_init_vars ()
#
#
#
{

	set -a

	printf -v TAB "\t"
	printf -v NLN "\n"

	SED_TYP=gnu
	{ { sed --version 2>&1 || true; } | grep -qwi gnu; } || SED_TYP=bsd
	case "${SED_TYP}" in
		( gnu ) {
			SED_XRG="-r"
			SED_LNB="-u"
		};;
		( bsd ) {
			SED_XRG="-E"
			SED_LNB="-l"
		};;
	esac

	__onset_v_dts_loc="$( __onset_f_dts_loc_now )"
	__onset_v_dts_loc_4fs="${__onset_v_dts_loc//:/-}"
	__onset_v_dts_loc_4fs="${__onset_v_dts_loc_4fs/T/_}"
	__onset_v_dts_utc="$( __onset_f_dts_utc_now )"
	__onset_v_dts_utc_4fs="${__onset_v_dts_utc//:/-}"
	__onset_v_dts_utc_4fs="${__onset_v_dts_utc_4fs/T/_}"
	__onset_v_sess=":${HOSTNAME}:${USER}:$$:${__onset_v_dts_utc_4fs}:"
	__onset_v_path="${BASH_SOURCE[$((${#BASH_SOURCE[@]}-1))]}"
	__onset_v_rdir="${PWD}"
	__onset_v_base="${__onset_v_path##*/}"
	[ "${__onset_v_path}" == "${__onset_v_base}" ] \
	&& __onset_v_sdir="." \
	|| __onset_v_sdir="${__onset_v_path%/*}"
	cd "${__onset_v_sdir}" \
	&& __onset_v_sdir="${PWD}" \
	&& cd "${__onset_v_rdir}"
	__onset_v_path="${__onset_v_sdir}/${__onset_v_base}"
	__onset_v_tdir="${TMPDIR}/${__onset_v_base}_${__onset_v_dts_loc_4fs}_$$"
	__onset_v_tdir_sec="${__onset_v_tdir}/sec"
	__onset_v_tdir_log="${__onset_v_tdir}/log"
	__onset_v_tdir_out="${__onset_v_tdir}/out"
	__onset_v_tdir_err="${__onset_v_tdir}/err"

	__onset_v_traps_bak="${__onset_v_traps_bak:-$( trap -p )}"
	#__onset_v_sigs=( EXIT ERR DEBUG $( trap -l | grep -ao "SIG[^[:blank:]]*" ) )
	#__onset_v_sigs=( EXIT $( trap -l | grep -ao "SIG[^[:blank:]]*" ) )
	__onset_v_sigs=( EXIT ERR SIGINT )
	__onset_v_flg_pipe_n_redir=0
	[ "${#BASH_SOURCE[@]}" -ne 0 ] || __onset_v_flg_pipe_n_redir=1

	__onset_v_flg_sourced=0
	[ "${BASH_SOURCE[0]}" == "${0}" ] || __onset_v_flg_sourced=1

	__onset_v_flg_interactive=0
	[[ $- != *i* ]] \
	&& shopt -s -o errexit \
	|| {
		__onset_v_flg_interactive=1
	}

	__onset_tmpv_err=100
	__onset_v_err_tdir_sec=$((__onset_tmpv_err++))
	__onset_v_err_pipe_n_redir=$((__onset_tmpv_err++))
	__onset_v_err_sourced=$((__onset_tmpv_err++))
	__onset_v_err_interactive=$((__onset_tmpv_err++))
	__onset_v_err_tdir=$((__onset_tmpv_err++))
	__onset_v_errs[${__onset_v_err_tdir_sec}]="Could not create secure temporary directory ( ${__onset_v_tdir_sec} )!"
	__onset_v_errs[${__onset_v_err_pipe_n_redir}]="ONSET was piped/redirected to bash, which is not allowed!\nTo override: { ONSET_ALLOW_PIPE_N_REDIR=1; }"
	__onset_v_errs[${__onset_v_err_sourced}]="Sourcing ONSET is not allowed!\nTo override: { ONSET_ALLOW_SOURCED=1; }"
	__onset_v_errs[${__onset_v_err_interactive}]="Loading ONSET in an interactive shell is not allowed!\nTo override: { ONSET_ALLOW_INTERACTIVE=1; }"
	__onset_v_errs[${__onset_v_err_tdir}]="Could not create temporary directory ( ${__onset_v_tdir} )!"

	__onset_v_debug="$((${ONSET_DEBUG:-0}?1:0))"
	__onset_v_allow_sourced="$((${ONSET_ALLOW_SOURCED:-0}?1:0))"
	__onset_v_allow_pipe_n_redir="$((${ONSET_ALLOW_PIPE_N_REDIR:-0}?1:0))"
	__onset_v_allow_interactive="$((${ONSET_ALLOW_INTERACTIVE:-0}?1:0))"

	mkdir -p "${__onset_v_tdir}" &>/dev/null \
	&& TMPDIR="${__onset_v_tdir}" \
	|| end "${__onset_v_err_tdir}"
	mktemp -d "${__onset_v_tdir_sec}" &>/dev/null \
	&& TMPDIRSEC="${__onset_v_tdir_sec}" \
	|| end "${__onset_v_err_tdir_sec}"

	set +a

	unset ${!__onset_tmpv*}

}

function __onset_f_init_shell ()
#
#
#
{

	UMASK="0077"

	__onset_tmpv_shopt_toset=(
		execfail
		expand_aliases
		#extdebug
		extglob
		extquote
		failglob
		force_fignore
		gnu_errfmt
		huponexit
		nullglob
		shift_verbose
		#sourcepath
	)

	__onset_tmpv_shopt_unset=(
		cdable_vars
		cdspell
		checkhash
		checkwinsize
		dotglob
		mailwarn
		nocaseglob
		nocasematch
		xpg_echo
	)

	__onset_tmpv_shellopt_toset=(
		braceexpand
		errtrace
		functrace
		hashall
		nounset
		pipefail
	)

	__onset_tmpv_shellopt_unset=(
		allexport
		keyword
		monitor
		noclobber
		notify
		posix
		privileged
		#verbose
		#xtrace
	)

	set -a -u

	IFS_BAK="${IFS_BAK:-${IFS:?"NO_IFS"}}"
	__onset_v_shopt_bak="${__onset_v_shopt_bak:-$( shopt -p )}"
	__onset_v_shellopt_bak="${__onset_v_shellopt_bak:-$( shopt -p -o )}"
	UMASK_BAK="${UMASK_BAK:-$(umask)}"

	umask ${UMASK}
	shopt -s ${__onset_tmpv_shopt_toset[*]}
	shopt -u ${__onset_tmpv_shopt_unset[*]}
	shopt -s -o ${__onset_tmpv_shellopt_toset[*]}
	shopt -u -o ${__onset_tmpv_shellopt_unset[*]}

	TMPDIR="${TMPDIR:-/tmp}"
	HOSTNAME="${HOSTNAME:-$(uname -n)}"
	USER="${USER:-$(id -nu)}"

	: "${HOSTNAME:?"NO_HOSTNAME"}"
	: "${USER:?"NO_USER"}"
	: "${PWD:?"NO_PWD"}"
	: "${TMPDIR:?"NO_TMPDIR"}"
	: "${BASH_SOURCE[0]:?"NO_BASH_SOURCE"}"

	set +a

	unset ${!__onset_tmpv*}

}

function __onset_f_show_variables ()
#
#
#
{
	declare __onset_f_show_variables_tmpv_{var,val,rgx,ary,dec,end,tab,nln}=
	printf -v __onset_f_show_variables_tmpv_tab "\t"
	printf -v __onset_f_show_variables_tmpv_nln "\n"
	for __onset_f_show_variables_tmpv_var in $( compgen -v )
	do
		[[ "${__onset_f_show_variables_tmpv_var:-}" != __onset_f_show_variables_tmpv* ]] || continue
		__onset_f_show_variables_tmpv_val="$( declare -p "${__onset_f_show_variables_tmpv_var:-}" )"
		[[ "${__onset_f_show_variables_tmpv_val:-}" =~ ${__onset_f_show_variables_tmpv_nln:-} ]] || {
			echo "${__onset_f_show_variables_tmpv_val:-}"
			continue
		}
		__onset_f_show_variables_tmpv_rgx="^declare [^= ]*a[^= ]* [^= ]*="
		[[ "${__onset_f_show_variables_tmpv_val:-}" =~ ${__onset_f_show_variables_tmpv_rgx:-} ]] \
		&& __onset_f_show_variables_tmpv_ary=1 \
		|| __onset_f_show_variables_tmpv_ary=0
		__onset_f_show_variables_tmpv_rgx="^declare [^= ]* [^= ]*="
		[[ "${__onset_f_show_variables_tmpv_val:-}" =~ ${__onset_f_show_variables_tmpv_rgx:-} ]] || :
		__onset_f_show_variables_tmpv_dec="${BASH_REMATCH[0]}"
		[ "${__onset_f_show_variables_tmpv_ary:-}" -eq 1 ] \
		&& {
			__onset_f_show_variables_tmpv_dec="${__onset_f_show_variables_tmpv_dec:-}("
			__onset_f_show_variables_tmpv_end=")"
		} \
		|| __onset_f_show_variables_tmpv_end=
		{
			printf %s "${__onset_f_show_variables_tmpv_dec:-}"
			echo "${__onset_f_show_variables_tmpv_val:-}" |
				tr "\t" "\0" |
				paste -s - |
				egrep -ao "(\"([^\"\\]*[\\][\"\\])*[^\"\\]*\"|\[[0-9]*\]=\"([^\"\\]*[\\][\"\\])*[^\"\\]*\")" |
				sed "s/'/\\\'/g;s/^\([^\"]*\)\"\(.*\)\"\$/\1\$'\2'/;s/[\\][\"]/\"/g" |
				paste -sd" " - | sed "s/${__onset_f_show_variables_tmpv_tab:-}/\\\n/g" |
				tr "\0" "\t" |
				sed "s/${__onset_f_show_variables_tmpv_tab:-}/\\\t/g;s/\$/${__onset_f_show_variables_tmpv_end:-}/"
		}
	done
}

FNCS=(
	__onset_f_init_shell
	__onset_f_init_vars
	__onset_f_init_trap
	"__onset_f_trap_flag interactive"
	"__onset_f_trap_flag sourced"
	"__onset_f_trap_flag pipe_n_redir"
)

for FNC in "${FNCS[@]:-}"
do
	eval ${FNC:-:} || { ERR="${?}"; : echo "[[[${ERR}]]]" 1>&2; break; }
done

eval "${SHOPT_HISTORY_BAK}"

return ${ERR}

}

#declare -F __onset_f_bail &>/dev/null && __onset_f_bail || :

__onset ${@:+"${@}"}
