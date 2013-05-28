#! /bin/bash

function _onset ()
{

	_onset_init_shell

	_onset_init_vars

	_onset_init_trap

	_onset_trap_pipe_n_redir

	_onset_trap_sourced

}

function _onset_trap_pipe_n_redir ()
{
	declare ERR_PIPE_N_DIR=2
	[ -n "${ALLOW_PIPE_N_REDIR+IS_DEF}" ] && return 0
	[ "${#BASH_SOURCE[@]}" -ne 0 ] \
		|| {
			echo "${0}: This script was piped/redirected to bash, which is not allowed! ( Declare ALLOW_PIPE_N_REDIR to override. )" 1>&2
			exit "${ERR_PIPE_N_DIR}"
		}
}

function _onset_trap_sourced ()
{
	declare ERR_SOURCED=3
	[ -n "${ALLOW_SOURCED+IS_DEF}" ] \
		&& return 0
	[ "${BASH_SOURCE[$((${#BASH_SOURCE[@]}-1))]}" == "${0}" ] \
		|| {
			echo "${0}: Sourcing this script is not allowed! ( Declare ALLOW_SOURCED to override. )" 1>&2
			return "${ERR_SOURCED}"
		}
}

function out ()
#
#
#
{ printf "${@}"; }

function err ()
#
#
#
{ printf "${_onset_name}: ${@}" 1>&2; }

function end ()
#
#
#
{
	declare ERR="${?}"
	err "${@}"
	exit "${ERR}"
}

function _onset_init_trap ()
{
	trap _onset_trap \
		EXIT SIGHUP SIGINT SIGQUIT SIGILL SIGTRAP SIGABRT SIGEMT SIGFPE \
		SIGBUS SIGSEGV SIGSYS SIGPIPE SIGALRM SIGTERM SIGURG SIGSTOP \
		SIGTSTP SIGCONT SIGCHLD SIGTTIN SIGTTOU SIGIO SIGXCPU SIGXFSZ \
		SIGVTALRM SIGPROF SIGWINCH SIGINFO SIGUSR1 SIGUSR2
}

function _onset_trap ()
{
	declare ERR="${?}"
	[ "${ERR}" -eq 0 ] \
		|| {
			declare MSG=
			set | egrep "^((BASH_SOURCE|FUNCNAME|PIPESTATUS|BASH_LINENO)(=|_BAK=)|BASH_ARG[CV]=)" |
				while read MSG
				do
					: #err "ENV: %s\n" "${MSG}"
				done
			: #err "ENV: ?=${ERR}\n"
			for I in {0..8}; do MSG="$(caller ${I})" && err "Caller ( ${MSG} )\n" || break; done
		}
	trap - EXIT
	_onset_bail
	exit "${ERR}"
}

function _onset_bail ()
{

	eval "${SHOPT_BAK}"
	eval "${SHELLOPT_BAK}"

}

function _onset_init_vars ()
#
#
#
{

	set -a

	printf -v TAB "\t"
	printf -v NLN "\n"

	SED_TYP=gnu
	{ { sed --version 2>&1 || true; } | grep -qwi gnu; } \
		|| SED_TYP=bsd
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

	_onset_dts="$(date "+%Y-%m-%dT%H:%M:%S")"
	_onset_dts_4fs="${_onset_dts//:/-}"
	_onset_dts_4fs="${_onset_dts_4fs/T/_}"
	_onset_sess=":${HOSTNAME}:${USER}:$$:${_onset_dts_4fs}:"
	_onset_rdir="${PWD}"
	_onset_tdir="${TMPDIR}"
	_onset_path="${BASH_SOURCE[$((${#BASH_SOURCE[@]}-1))]}"
	_onset_base="${_onset_path##*/}"
	[ "${_onset_path}" == "${_onset_base}" ] \
		&& _onset_sdir="." \
		|| _onset_sdir="${_onset_path%/*}"
	cd "${_onset_sdir}" \
		&& _onset_sdir="${PWD}" \
		&& cd "${_onset_rdir}"
	_onset_path="${_onset_sdir}/${_onset_base}"
	_onset_name="${_onset_base%.bash}"
	_onset_name="${_onset_name%.sh}"
	_onset_tdir_sec="${_onset_tdir}/${_onset_name}_${_onset_dts_4fs}_$$"

	set +a

	mktemp -d "${_onset_tdir_sec}" &>/dev/null || end "Could not Create TempDir Secure [ ${_onset_tdir_sec} ]"

}

function _onset_init_shell ()
#
#
#
{

	UMASK="0077"

	SHOPT_TOSET=(
		execfail
		expand_aliases
		extdebug
		extglob
		extquote
		failglob
		force_fignore
		gnu_errfmt
		huponexit
		nullglob
		shift_verbose
		sourcepath
	)

	SHOPT_UNSET=(
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

	SHELLOPT_TOSET=(
		braceexpand
		errexit
		errtrace
		functrace
		hashall
		nounset
		pipefail
	)

	SHELLOPT_UNSET=(
		allexport
		keyword
		monitor
		noclobber
		notify
		posix
		privileged
		verbose
		xtrace
	)

	set -a -u

	IFS_BAK="${IFS:?"NO_IFS"}"
	SHOPT_BAK="$(shopt -p)"
	SHELLOPT_BAK="$(shopt -p -o)"
	UMASK_BAK="$(umask)"

	umask ${UMASK}
	shopt -s ${SHOPT_TOSET[*]}
	shopt -u ${SHOPT_UNSET[*]}
	shopt -s -o ${SHELLOPT_TOSET[*]}
	shopt -u -o ${SHELLOPT_UNSET[*]}

	TMPDIR="${TMPDIR:-/tmp}"
	HOSTNAME="${HOSTNAME:-$(uname -n)}"
	USER="${USER:-$(id -nu)}"

	: "${HOSTNAME:?"NO_HOSTNAME"}"
	: "${USER:?"NO_USER"}"
	: "${PWD:?"NO_PWD"}"
	: "${TMPDIR:?"NO_TMPDIR"}"
	: "${BASH_SOURCE[0]:?"NO_BASH_SOURCE"}"

	set +a

}

_onset "${@}"

