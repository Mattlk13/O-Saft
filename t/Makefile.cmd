#! /usr/bin/make -rRf
#?
#? DESCRIPTION
#?      For more details please see
#?          ../Makefile  Makefile  Makefile.help  Makefile.pod
#?      make help.test.cmd
#?
#? VERSION
#?      @(#) Makefile.cmd 1.55 22/02/21 13:08:03
#?
#? AUTHOR
#?      18-apr-18 Achim Hoffmann
#?
# -----------------------------------------------------------------------------

HELP-help.test.cmd  = targets for testing '$(SRC.pl)' commands and options

_SID.cmd           := 1.55

_MYSELF.cmd        := t/Makefile.cmd
ALL.includes       += $(_MYSELF.cmd)
ALL.inc.type       += cmd
ALL.help.tests     += help.test.cmd

ifeq (,$(_SID.test))
    -include t/Makefile
endif

TEST.cmd.hosts      = localhost
ifdef TEST.hosts
    TEST.cmd.hosts  = $(TEST.hosts)
endif

first-cmd-target-is-default: help.test.cmd

help.test.cmd:        HELP_TYPE = cmd
help.test.cmd-v:      HELP_TYPE = cmd
help.test.cmd-vv:     HELP_TYPE = cmd

HELP-_cmd1          = _________________________________________ testing commands _
HELP-test.pattern-* = test group of commands with '$(TEST.cmd.hosts)'
HELP-testcmd-*      = test commands with '$(TEST.cmd.hosts)'
HELP-testcmd-*.log  = same as testcmd-* but store output in '$(TEST.logdir)/'
HELP-test.cmd       = test all commands with '$(TEST.cmd.hosts)'
HELP-test.cmd.log   = same as test.cmd but store output in '$(TEST.logdir)/'
HELP-_cmd2          = ________________________________ testing a special command _
HELP-testrun-CMD    = test specific command CMD with '$(TEST.cmd.hosts)'
HELP-testrun-CMD.log = same as testrun-CMD but store output in '$(TEST.logdir)/'
HELP-_cmd3          = __________________________________________ special targets _
HELP-testcmd-cmd+ignored-keys = special target using commands which return random values

HELP.cmd            = $(_NL)\
\# Targets can be executed individually, or a group of targets can be executed$(_NL)\
\# by using the pattern rule  test.pattern-%  (see Makefile).$(_NL)\
\# Examples to execute individual targets:$(_NL)\
\#    $(MAKE_COMMAND) testcmd-cmd+info_localhost$(_NL)\
\#    $(MAKE_COMMAND) testcmd-cmd_vuln+BEAST_localhost$(_NL)\
\#    $(MAKE_COMMAND) testrun-+cn$(_NL)\
\# Examples to execute group of similar targets:$(_NL)\
\#    $(MAKE_COMMAND) test.pattern-+info$(_NL)\
\#    $(MAKE_COMMAND) test.pattern-+check$(_NL)\
\#    $(MAKE_COMMAND) test.pattern-+summ$(_NL)\
\#    $(MAKE_COMMAND) test.pattern-+vuln$(_NL)\
\#$(_NL)\
\# Some of the examples above use  localhost  as hostname by default.

HELP.test.cmd.all   = # no special documentation yet

# SEE Make:--ignore-output
LIST.ignore-output-keys := master_key \
			   session_id session_id_ctx \
			   session_startdate session_starttime \
			   session_ticket sts_expired
LIST.no-out.opt    := $(LIST.ignore-output-keys:%=--no-out=%)
LIST.ignore.cmd    := $(LIST.ignore-output-keys:%=+%)
    # The  ignored keys are tested with the target  testcmd-cmd-+ignored-keys_ .
LIST.cmd.withtrace := +quit +info  +check
    # various --trace* options to be used with these commands
    #   +quit  - the most simple output, no call to a target
    #   +info  - output with call to a target, hence trace from Net/SSLinfo.pm also
    #   +check - some more output from $(EXE.pl) than with +info
    #   +cipher - # TODO
LIST.cmd.cmd       := $(LIST.cmd.withtrace) +quick +vulns +http +hsts +sts
LIST.cmd.vulns     := +BEAST +CRIME +DROWN +FREAK +POODLE +logjam +lucky13 +Sloth +Sweet32
LIST.cmd.summ      := +bsi  +EV +TR-02102+ +ocsp  +preload +protocols +fingerprints +sizes +pfs +sni
LIST.cmd.trace-opt := --tracearg --tracecmd --tracekey --tracetime --traceme --trace --trace=2
    # --trace* options used instead --trace-*; make nicer target names
    # Note that  --tracecmd is same as --traceCMD is same as --trace-CMD

_TEST.cmd          := testcmd-cmd

# SEE Make:target name
# SEE Make:target name prefix

ifndef cmd-targets-generated
    # arguments from LIST.* used in the target name must not contain =
    # hence $(subst =,-,$(arg)) is used to replace = by -

    # target foreach command
    $(foreach cmd, $(LIST.cmd.cmd) $(LIST.cmd.vulns) $(LIST.cmd.summ),\
	$(eval $(_TEST.cmd)-$(subst =,-,$(cmd))_%:  TEST.args += $(cmd) ) \
	$(eval ALL.testcmd  += $(_TEST.cmd)-$(subst =,-,$(cmd))_ ) \
    )
    # targets without --trace* options
    $(foreach cmd, $(LIST.cmd.withtrace),\
	$(eval $(_TEST.cmd)-$(subst =,-,$(cmd))--noout_%:  TEST.args += $(cmd) $(LIST.no-out.opt) ) \
	$(eval ALL.testcmd  += $(_TEST.cmd)-$(subst =,-,$(cmd))--noout_ ) \
      $(foreach opt, $(LIST.cmd.trace-opt),\
	$(eval $(_TEST.cmd)-$(subst =,-,$(cmd))$(subst =,-,$(opt))_%:  TEST.args += $(cmd) $(opt) $(LIST.no-out.opt) ) \
	$(eval ALL.testcmd  += $(_TEST.cmd)-$(subst =,-,$(cmd))$(subst =,-,$(opt))_ ) \
      ) \
    )
endif

# TODO: need generic target which compares results of initial command
#       with same command and more options, example:
#           testcmd-cmd-+info_localhost testcmd-cmd-+info--noout_localhost

testcmd-cmd-%:                      EXE.pl      = ../$(SRC.pl)
testcmd-cmd-%:                      TEST.init   = --trace-CLI --header

testcmd-cmd-+ignored-keys_%:        TEST.args += $(LIST.ignore.cmd)
# avoid output of random values in some commands
testcmd-cmd-+http_%:                TEST.args += --no-out=sts_expired
testcmd-cmd-+hsts_%:                TEST.args += --no-out=sts_expired
testcmd-cmd-+sts_%:                 TEST.args += --no-out=sts_expired
testcmd-cmd-+sts--noout_%:          TEST.args += +sts   $(LIST.no-out.opt)
testcmd-cmd-+info--tracekey-norc_%: TEST.args += +info  --trace-key --norc $(LIST.no-out.opt)
testcmd-cmd-+check--tracekey-norc_%: TEST.args += +check --trace-key --norc $(LIST.no-out.opt)
testcmd-cmd-+check--trace-norc_%:   TEST.args += +check --trace-cmd --norc --trace-time --trace=2 $(LIST.no-out.opt)
testcmd-cmd-+quick--tracearg_%:     TEST.args += +quick --trace-arg
testcmd-cmd-+check--nossltls_%:     TEST.args += +check --nosslv2 --nosslv3 --notlsv1 --notlsv11 --notlsv12 --notlsv13 $(LIST.no-out.opt)
    #    simulates a server not responding to ciphers

ALL.testcmd    += \
	testcmd-cmd-+ignored-keys_ \
	testcmd-cmd-+sts--noout_   \
	testcmd-cmd-+info--tracekey-norc_ \
	testcmd-cmd-+check--tracekey-norc_ \
	testcmd-cmd-+check--trace-norc_ \
	testcmd-cmd-+quick--tracearg_ \
	testcmd-cmd-+check--nossltls_

testarg-cmd-host_url+cn:        TEST.args  += --v +cn
testarg-cmd-host_url+cn:        TEST.init   = localhost/tests
    # target to test hostname with url (path) # TODO: add to ALL.testcmd

ALL.test.cmd        = $(foreach host,$(TEST.cmd.hosts),$(ALL.testcmd:%=%$(host)))
ALL.test.cmd       += testarg-cmd-host_url+cn
ALL.test.cmd.log   += $(ALL.test.cmd:%=%.log)

# testrun target to allow something like:  testrun-+my-fancy-command
testrun-%:  EXE.pl      = ../$(SRC.pl)
testrun-%:  TEST.init   = --trace-CLI
testrun-%:  TEST.args  += $(TEST.cmd.hosts)
testrun-%:
	@$(TRACE.target)
	-cd $(TEST.dir) && $(EXE.pl) $(TEST.init) $* $(TEST.args)


test.cmd.log-compare:   TEST.target_prefix  = testcmd-cmd-
test.cmd.log-move:      TEST.target_prefix  = testcmd-cmd-
test.cmd.log:           TEST.target_prefix  = testcmd-cmd-

test.cmd:           $(ALL.test.cmd)
test.cmd.log:       $(ALL.test.cmd.log) test.log-compare-hint
