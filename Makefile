#! /usr/bin/make -rRf
#?
#? NAME
#?      Makefile        - makefile for O-Saft project
#?
#? SYNOPSYS
#?      make [options] [target] [...]
#?
#? DESCRIPTION
#?      For help about the targets herein, please see:
#?
#?          make
#?          make help
#?
#?      For detailled documentation how GNU Make, its syntax and conventions as
#?      well as some special syntax of macros and targets is used here,  please
#?      refer to  Makefile.pod , for example by using  "perldoc Makefile.pod" .
#?      The term  "SEE Make:some text"  is used to reference to Makefile.pod .
#
# HACKER's INFO
#       For the public available targets see below of  "well known targets" .
#?
#? VERSION
#?      @(#) Makefile 1.100 19/12/04 23:44:55
#?
#? AUTHOR
#?      21-dec-12 Achim Hoffmann
#?
# -----------------------------------------------------------------------------

_SID            = 1.100
                # define our own SID as variable, if needed ...
                # SEE O-Saft:Makefile Version String
                # Known variables herein (8/2019) to be changed are:
                #     _SID
                #     _INST.text
                #     GREP_EDIT

ALL.includes   := Makefile
                # must be  :=  to avoid overwrite after includes
                # each $(TEST.dir)/Makefile* will add itself to ALL.includes

MAKEFILE        = Makefile
                # define variable for myself,  this allows to use  some targets
                # within other makefiles
                # Note that  $(MAKEFILE) is used where any Makefile is possible
                # and  Makefile  is used when exactly this file is meant.
                # $(ALL.Makefiles) is used, when all Makefiles are needed.

MAKEFLAGS       = --no-builtin-variables --no-builtin-rules
.SUFFIXES:

.DEFAULT:
	@echo "**ERROR: unknown target '$(MAKECMDGOALS)'"

first-target-is-default: help

#_____________________________________________________________________________
#________________________________________________________________ variables __|

Project         = o-saft
ProjectName     = O-Saft
INSTALL.dir     = /usr/local/$(Project)

# source files
SRC.lic         = yeast.lic
DEV.pl          = yeast.pl
CHK.pl          = checkAllCiphers.pl
OSD.dir         = OSaft/Doc
OSD.pm          = OSaft/Doc/Data.pm
OSD.txt         = \
		  coding.txt \
		  glossary.txt \
		  help.txt \
		  links.txt \
		  misc.txt \
		  rfc.txt \
		  tools.txt
SRC.txt         = $(OSD.txt:%=$(OSD.dir)/%)
NET.pm          = SSLinfo.pm \
		  SSLhello.pm
_CIPHER         = \
		  _ciphers_osaft.pm \
		  _ciphers_iana.pm \
		  _ciphers_openssl_all.pm \
		  _ciphers_openssl_low.pm \
		  _ciphers_openssl_medium.pm \
		  _ciphers_openssl_high.pm
# add to SRC.pm  $(_CIPHER:%=OSaft/%)  when used
OSAFT.pm        = Ciphers.pm error_handler.pm
USR.pm          = \
		  $(Project)-dbx.pm \
		  $(Project)-man.pm \
		  $(Project)-usr.pm
SRC.pm          = \
		  osaft.pm \
		  $(NET.pm:%=Net/%)   \
		  $(OSAFT.pm:%=OSaft/%) \
		  $(USR.pm) \
		  $(OSD.pm)
SRC.sh          = $(Project)
SRC.pl          = $(Project).pl
SRC.tcl         = $(Project).tcl
SRC.gui         = $(Project).tcl $(Project)-img.tcl
SRC.cgi         = $(Project).cgi
SRC.php         = $(Project).php
SRC.docker      = \
		  $(Project)-docker \
		  $(Project)-docker-dev \
		  Dockerfile
SRC.rc          = .$(SRC.pl)

SRC.make        = Makefile
SRC.misc        = README CHANGES
SRC.inst        = $(CONTRIB.dir)/INSTALL-template.sh

# contrib files
CONTRIB.dir     = contrib
CONTRIB.examples= filter_examples usage_examples
CONTRIB.post.awk= \
		  Cert-beautify.awk Cert-beautify.pl \
		  HTML-simple.awk HTML-table.awk \
		  JSON-array.awk JSON-struct.awk \
		  XML-attribute.awk XML-value.awk \
		  lazy_checks.awk
CONTRIB.post    = bunt.pl bunt.sh symbol.pl
CONTRIB.misc    = \
		  cipher_check.sh \
		  critic.sh \
		  gen_standalone.sh \
		  distribution_install.sh \
		  install_openssl.sh \
		  install_perl_modules.pl \
		  INSTALL-template.sh \
		  Dockerfile.alpine-3.6

CONTRIB.zap     = zap_config.sh zap_config.xml
# some file should get the $(Project) suffix, which is appended later
CONTRIB.complete= \
		  bash_completion \
		  dash_completion \
		  fish_completion \
		  tcsh_completion
SRC.contrib     = \
		  $(CONTRIB.complete:%=$(CONTRIB.dir)/%_$(Project)) \
		  $(CONTRIB.examples:%=$(CONTRIB.dir)/%) \
		  $(CONTRIB.post.awk:%=$(CONTRIB.dir)/%) \
		  $(CONTRIB.post:%=$(CONTRIB.dir)/%) \
		  $(CONTRIB.misc:%=$(CONTRIB.dir)/%) \
		  $(CONTRIB.zap:%=$(CONTRIB.dir)/%)

# test files
TEST.dir        = t
TEST.logdir     = $(TEST.dir)/log
TEST.do         = SSLinfo.pl \
                  o-saft_bench.sh \
                  critic_345.sh \
                  test-bunt.pl.txt
CRITIC.rc       = .perlcriticrc
SRC.test        = \
                  $(TEST.do:%=$(TEST.dir)/%) \
                  $(CRITIC.rc:%=$(TEST.dir)/%)

# documentation files
DOC.dir         = docs
DOC.src         = o-saft.odg o-saft.pdf o-saft-docker.pdf
SRC.doc         = $(DOC.src:%=$(DOC.dir)/%)
WEB.dir         = docs/img
WEB.src         = \
		  img.css \
		  O-Saft_CLI-cipher.png \
		  O-Saft_CLI-altname.png \
		  O-Saft_GUI-altname.png \
		  O-Saft_GUI-check.png \
		  O-Saft_GUI-cmd--docker.png \
		  O-Saft_GUI-cmd.png \
		  O-Saft_GUI-cmd-0.png \
		  O-Saft_GUI-filter.png \
		  O-Saft_GUI-help-0.png \
		  O-Saft_GUI-help-1.png \
		  O-Saft_GUI-opt.png \
		  O-Saft_GUI-prot.png \
		  O-Saft_GUI-vulns.png \
		  O-Saft_CLI-vulns.png \
		  O-Saft_CLI__faked.txt
SRC.web         = $(WEB.src:%=$(WEB.dir)/%)

# generated files
TMP.dir         = /tmp/$(Project)
GEN.html        = $(DOC.dir)/$(Project).html
GEN.cgi.html    = $(DOC.dir)/$(Project).cgi.html
GEN.text        = $(DOC.dir)/$(Project).txt
GEN.wiki        = $(DOC.dir)/$(Project).wiki
GEN.man         = $(DOC.dir)/$(Project).1
GEN.pod         = $(DOC.dir)/$(Project).pod
GEN.src         = $(CONTRIB.dir)/$(Project)-standalone.pl
GEN.inst        = INSTALL.sh
GEN.tags        = tags
GEN.rel         = $(Project).rel

GEN.tgz         = $(Project).tgz
GEN.tmptgz      = $(TMP.dir)/$(GEN.tgz)

# summary variables
GEN.docs        = $(GEN.pod) $(GEN.html) $(GEN.cgi.html) $(GEN.text) $(GEN.wiki) $(GEN.man)
SRC.exe         = $(SRC.pl)  $(SRC.gui) $(CHK.pl)  $(DEV.pl) $(SRC.sh)
inc.Makefiles   = \
		  Makefile         Makefile.inc   Makefile.help  Makefile.pod \
		  Makefile.opt     Makefile.cmd   Makefile.ext   Makefile.exit \
		  Makefile.cgi     Makefile.tcl   Makefile.misc  Makefile.warnings \
		  Makefile.critic  Makefile.etc   Makefile.template \
		  Makefile.dev     Makefile.FQDN  Makefile.examples
# NOTE: sequence in ALL.Makefiles is important, for example when used in target doc
ALL.Makefiles   = $(SRC.make) $(inc.Makefiles:%=$(TEST.dir)/%)
ALL.osaft       = $(SRC.pl)  $(SRC.gui) $(CHK.pl)  $(SRC.pm)  $(SRC.sh) $(SRC.txt) $(SRC.rc) $(SRC.docker)
ALL.exe         = $(SRC.exe) $(SRC.cgi) $(SRC.php) $(GEN.src) $(SRC.docker)
ALL.tst         = $(SRC.test)
ALL.contrib     = $(SRC.contrib)
ALL.doc         = $(SRC.doc) $(SRC.web)
ALL.pm          = $(SRC.pm)
ALL.gen         = $(GEN.src) $(GEN.pod) $(GEN.html) $(GEN.cgi.html) $(GEN.text) $(GEN.man) $(GEN.inst)
ALL.docs        = $(SRC.doc) $(GEN.docs)
    # NOTE: ALL.docs is are the files for user documentation, ALL.doc are SRC-files
#               # $(GEN.tags) added in t/Makefile.misc
#               # $(GEN.wiki) not part of ALL.gen as rarly used
ALL.src         = \
		  $(ALL.exe) \
		  $(ALL.pm) \
		  $(SRC.txt) \
		  $(SRC.rc) \
		  $(SRC.misc) \
		  $(SRC.doc) \
		  $(ALL.gen) \
		  $(ALL.Makefiles) \
		  $(ALL.tst) \
		  $(ALL.contrib)
ALL.tgz         = $(ALL.src:%=O-Saft/%)

# tools for targets
ECHO            = /bin/echo -e
MAKE            = $(MAKE_COMMAND)
# some rules need to have a command, otherwise they are not evaluated
EXE.dummy       = /bin/echo -n ""

# internal used tools (paths hardcoded!)
EXE.single      = contrib/gen_standalone.sh
EXE.docker      = o-saft-docker
EXE.pl          = $(SRC.pl)
#                   SRC.pl is used for generating a couple of data

# INSTALL.sh must not contain duplicate files, hence the variable's content
# is sorted using make's built-in sort which removes duplicates
_INST.osaft_cgi = $(sort $(SRC.cgi) $(SRC.php) $(GEN.cgi.html))
_INST.osaft_doc = $(sort $(GEN.pod) $(GEN.man) $(GEN.html))
_INST.contrib   = $(sort $(ALL.contrib))
_INST.osaft     = $(sort $(ALL.osaft))
_INST.text      = generated from Makefile 1.100
EXE.install     = sed   -e 's@INSTALLDIR_INSERTED_BY_MAKE@$(INSTALL.dir)@'    \
			-e 's@CONTRIBDIR_INSERTED_BY_MAKE@$(CONTRIB.dir)@'    \
			-e 's@CONTRIB_INSERTED_BY_MAKE@$(_INST.contrib)@'     \
			-e 's@OSAFT_INSERTED_BY_MAKE@$(_INST.osaft)@'         \
			-e 's@OSAFT_PL_INSERTED_BY_MAKE@$(SRC.pl)@'           \
			-e 's@OSAFT_GUI_INSERTED_BY_MAKE@$(SRC.tcl)@'         \
			-e 's@OSAFT_CGI_INSERTED_BY_MAKE@$(_INST.osaft_cgi)@' \
			-e 's@OSAFT_DOC_INSERTED_BY_MAKE@$(_INST.osaft_doc)@' \
			-e 's@INSERTED_BY_MAKE@$(_INST.text)@'
                # last substitude is fallback to ensure everything is changed

# generate f- targets to print HELP text for each target
_HELP.my_targets= $(shell $(EXE.eval) $(MAKEFILE))
_HELP.alltargets= $(shell $(EXE.eval) $(ALL.includes))
_HELP.help      = $(ALL.help:%=f-%)
                # quick&dirty because each target calls make (see below)

#_____________________________________________________________________________
#___________________________________________________________ default target __|

# define header part of default target
help:           HELP_HEAD = $(HELP_RULE)
help.all:       HELP_HEAD = $(HELP_RULE)
help.log:       HELP_HEAD = $(HELP_RULE)
help.all.log:   HELP_HEAD = $(HELP_RULE)
doc:            HELP_HEAD = $(HELP_RULE)
doc.all:        HELP_HEAD = $(HELP_RULE)

# define body part of default target
# TODO: adapt _help_* macros and targets according own naming convention
_help_also_               = _help_also
_help_body_               = _help_body_me
_help_list_               =
help.all:     _help_body_ = _help_body_all
help.all:     _help_list_ = _help_list
doc:          _help_body_ = _eval_body_me
doc.all:      _help_body_ = _eval_body_all
doc:          _help_also_ =
doc.all:      _help_also_ =
doc.all:      _help_list_ = _help_list

# for targets defined in Makefile.help
help.all%:    _help_body_ = _help_body_all
help.all%:    _help_list_ = _help_list
%.all-v:     _help_text-v =
_help_text-v              = \# to see Makefile, where targets are defined, use: $(MAKE_COMMAND) $(MAKECMDGOALS)-v

#_____________________________________________________________________________
#_________________________________________________________ internal targets __|

# SEE Make:.SECONDEXPANSION
.SECONDEXPANSION:

# If variables, like  $(_HELP.*targets),  contain duplicate target names (which
# is intended), only one will be executed by  $(MAKE),  hence the 2nd occurance
# is missing.
_eval_body_me:
	@$(MAKE) -s $(_HELP.my_targets)
	@echo "$(HELP_LINE)"

_eval_body_all:
	@$(MAKE) -s $(_HELP.alltargets)

_help_body_me:
	@$(EXE.help) $(MAKEFILE)
	@echo "$(HELP_LINE)"

_help_body_all:
	@$(EXE.help) $(ALL.includes)

_help_list:
	@echo ""
	@echo "		#___________ targets for information about test targets... _"
	@$(MAKE) $(_HELP.help)
	@echo "$(HELP_LINE)"
	@echo "$(_help_text-v)"

_help_also:
	@echo "# to expand variables, use: $(MAKE_COMMAND) doc"

# ensure that target help: from this file is used and not help%
help help.all doc doc.all: _help.HEAD $$(_help_body_) $$(_help_list_) $$(_help_also_)
	@$(TRACE.target)

help.all-v help.all-vv: help.all
	@$(EXE.dummy)
#doc.all-v doc.all-vv: help.all     # TODO: not implemented yet

.PHONY: help help.all doc doc.all

#_____________________________________________________________________________
#__________________________________________________________________ targets __|

HELP-_known     = _______________________________________ well known targets _
HELP-all        = does nothing; alias for help
HELP-clean      = remove all generated files '$(ALL.gen) $(GEN.wiki) $(GEN.tags)'
HELP-release    = generate signed '$(GEN.tgz)' from sources
HELP-install    = install tool in '$(INSTALL.dir)' using '$(GEN.inst)', $(INSTALL.dir) must exist
HELP-uninstall  = remove installtion directory '$(INSTALL.dir)' completely

$(INSTALL.dir):
	@$(TRACE.target)
	mkdir $(_INSTALL_FORCE_) $(INSTALL.dir)

all:    help

clean:  clean.tmp clean.tar clean.gen
clear:  clean

# target calls installed $(SRC.pl) to test general functionality
install: $(GEN.inst) $(INSTALL.dir)
	@$(TRACE.target)
	$(GEN.inst) $(INSTALL.dir) \
	    && $(INSTALL.dir)/$(SRC.pl) --no-warning --tracearg +quit > /dev/null
install-f: _INSTALL_FORCE_ = -p
install-f: install

uninstall:
	@$(TRACE.target)
	-rm -r --interactive=never $(INSTALL.dir)

_RELEASE    = $(shell perl -nle '/^\s*STR_VERSION/ && do { s/.*?"([^"]*)".*/$$1/;print }' $(SRC.pl))

release.show:
	@echo "Release: $(_RELEASE)"

release: $(GEN.tgz)
	@$(TRACE.target)
	mkdir -p $(_RELEASE)
	sha256sum $(GEN.tgz) > $(_RELEASE)/$(GEN.tgz).sha256
	@cat $(_RELEASE)/$(GEN.tgz).sha256
	gpg --local-user o-saft -a --detach-sign $(GEN.tgz)
	gpg --verify $(GEN.tgz).asc $(GEN.tgz)
	mv $(GEN.tgz).asc $(_RELEASE)/
	mv $(GEN.tgz)     $(_RELEASE)/
	@echo "# don't forget:"
	@echo "#   # change digest: sha256:... in README; upload to github"
	@echo "#   # change digest: sha256:... in Dockerfile; upload to github"
	@echo "#   make docker"
	@echo "#   make test.docker"
	@echo "#   make docker.push"
# TODO: check if files are edited or missing

# Generating a release file, containing all files with their SID.
# This file should be easily readable by humans and easily parsable by scripts,
# hence following format is used (one per line):
#    SID\tdate\ttime\tfilename\tfull_path
# How it works:
#    "sccs what" returns multiple lines, at least 2, these look like:
#      path/filename:
#          o-saft.pl 1.823 18/11/18 23:42:23
#    this is resorted to have the fixed-width field  SID, date and time  at the
#    beginning (left), followed by the  filename and the full path.
# what may also return lines like:
#          @(#) filename 1.245 19/11/19 12:23:42',
#          @(#) filename generated by 1.227 19/11/19 10:12:13
# The perl script takes care of them  and ignores or pretty prints the strings. 
# The "generated by" may occour i.e. in o-saft.tcl.
# NOTE: only files available in the repository are used, therefore the variable
#       $(ALL.src)  is used. Because $(ALL.src) also contains $(ALL.gen), which
#       is wrong here, $(ALL.gen) is  set empty for this target.
#    o-saft.pl is generated from yeast.pl,  but  o-saft.pl  is not a repository
#    file, hence yeast is substituded by o-saft (should occour only once).
$(GEN.rel):   ALL.gen =
$(GEN.rel): $(ALL.src)
	@sccs what $(ALL.src) | \
	perl -anle '/ generated by /&&next;/^(.*):$$/&&do{$$f=$$m=$$1;$$m=~s#.*/##;next;};/.*?($$m|%[M]%)/&&do{$$f=~s/yeast/o-saft/;$$F[0]=~s/yeast/o-saft/;$$t=$$F[3];$$q=chr(0x27);$$t=~s#["$$q,]##g;printf("%s\t%s\t%s\t%s\t%s\n",$$F[1],$$F[2],$$t,$$F[0],$$f)};'
rel :$(GEN.rel)

$(_RELEASE).rel: Makefile
	@$(MAKE) -s $(GEN.rel) > $@


.PHONY: all clean install install-f uninstall release.show release rel

variables       = \$$(variables)
#               # define literal string $(variables) for "make doc"
HELP-_project   = ____________________________________ targets for $(Project) _
HELP-help       = print common targets for O-Saft (this help)
HELP-doc        = same as help, but evaluates '$(variables)'
HELP-pl         = generate '$(SRC.pl)' from managed source files
HELP-cgi        = generate HTML page for use with CGI '$(GEN.cgi.html)'
HELP-man        = generate MAN format help '$(GEN.man)'
HELP-pod        = generate POD format help '$(GEN.pod)'
HELP-html       = generate HTML format help '$(GEN.html)'
HELP-text       = generate plain text  help '$(GEN.text)'
HELP-wiki       = generate mediawiki format help '$(GEN.wiki)'
HELP-tar        = generate '$(GEN.tgz)' from all source prefixed with O-Saft/
HELP-tmptar     = generate '$(GEN.tmptgz)' from all sources without prefix
HELP-gen.all    = generate most "generatable" file
HELP-docker     = generate local docker image (release version) and add updated files
HELP-docker.dev = generate local docker image (development version)
HELP-docker.push= install local docker image at Docker repository
HELP-clean.tmp  = remove '$(TMP.dir)'
HELP-clean.tar  = remove '$(GEN.tgz)'
HELP-clean.gen  = remove '$(ALL.gen)' '$(GEN.wiki)' '$(GEN.inst)' '$(GEN.tags)'
HELP-clean.all  = remove '$(ALL.gen)' '$(GEN.wiki)' '$(GEN.inst)' '$(GEN.tags)' '$(GEN.tgz)'
HELP-install-f  = install tool in '$(INSTALL.dir)' using '$(GEN.inst)', $(INSTALL.dir) may exist
HELP-o-saft.rel = generate '$(GEN.rel)'
#               # HELP-o-saft.rel hardcoded, grrr


HELP-_vv1       = ___________ any target may be used with following suffixes _
HELP--v         = verbose: print target and newer dependencies also
HELP--vv        = verbose: print target and all dependencies also

HELP-_project2  = __________________ targets to get more help and information _
HELP-help.all   = print all targets, including test and development targets
#               # defined in t/Makefile.help also
HELP-help.help  = print targets to get information/documentation from Makefiles

# alias targets
pl:     $(SRC.pl)
cgi:    $(GEN.cgi.html)
man:    $(GEN.man)
pod:    $(GEN.pod)
html:   $(GEN.html)
text:   $(GEN.text)
wiki:   $(GEN.wiki)
standalone: $(GEN.src)
tar:    $(GEN.tgz)
GREP_EDIT           = 1.100
tar:     GREP_EDIT  = 1.100
tmptar:  GREP_EDIT  = something which hopefully does not exist in the file
tmptar: $(GEN.tmptgz)
tmptgz: $(GEN.tmptgz)
cleangen:   clean.gen
cleantar:   clean.tar
cleantgz:   clean.tar
cleantmp:   clean.tmp
cleartar:   clean.tar
cleartgz:   clean.tar
cleartmp:   clean.tmp
clear.all:  clean.tar clean
clean.all:  clean.tar clean
tgz:        tar
gen.all:    $(ALL.gen)

# docker target uses project's own script to build and remove the image
docker.build:
	@$(TRACE.target)
	$(EXE.docker) -OSAFT_VERSION=$(_RELEASE) build
	$(EXE.docker) cp Dockerfile
	$(EXE.docker) cp README
docker: docker.build

docker.rm:
	@$(TRACE.target)
	$(EXE.docker) rmi

docker.dev:
	@$(TRACE.target)
	docker build --force-rm --rm \
		--build-arg "OSAFT_VM_SRC_OSAFT=https://github.com/OWASP/O-Saft/archive/master.tar.gz" \
		--build-arg "OSAFT_VERSION=$(_RELEASE)" \
		-f Dockerfile -t owasp/o-saft .

# TODO: docker.push  should depend on  docker.build  (above), but  docker.build
#       is not a file and creates a Docker image; means that this target itself
#       has no dependency. Make then executes the target always, which fails if
#       a Docker image already exists.  Need a target, which checks the current
#       Docker image for the proper version.
docker.push:
	@$(TRACE.target)
	docker push owasp/o-saft:latest

.PHONY: pl cgi man pod html wiki standalone tar tmptar tmptgz cleantar cleantmp help
.PHONY: docker docker.rm docker.dev docker.push

clean.gen:
	@$(TRACE.target)
	rm -rf $(ALL.gen) $(GEN.wiki) $(GEN.inst)
clean.tmp:
	@$(TRACE.target)
	rm -rf $(TMP.dir)
clean.tar:
	@$(TRACE.target)
	rm -rf $(GEN.tgz)
clean.tgz: clean.tar
clean.docker: docker.rm

# avoid matching implicit rule help% in some of following targets
$(OSD.dir)/help.txt: 
	@$(TRACE.target)

#_____________________________________________________________________________
#_______________________________________________ targets for generated files__|

# targets for generation
$(TMP.dir)/Net $(TMP.dir)/OSaft $(TMP.dir)/OSaft/Doc $(TMP.dir)/$(CONTRIB.dir) $(TMP.dir)/$(TEST.dir):
	@$(TRACE.target)
	mkdir -p $@

# cp fails if SRC.pl is read-only, hence we remove it; it is generated anyway
$(SRC.pl): $(DEV.pl)
	@$(TRACE.target)
	rm -f $@
	cp $< $@

# generation fails if GEN.src is read-only, hence we remove it; it is generated anyway
$(GEN.src):  $(EXE.single) $(SRC.pl) $(ALL.pm)
	@$(TRACE.target)
	@rm -rf $@
	$(EXE.single) --s                              > $@
	@chmod 555 $@

$(GEN.man):  $(SRC.pl) $(OSD.pm) $(USR.pm) $(SRC.txt) $(GEN.pod)
	@$(TRACE.target)
	$(SRC.pl) --no-rc --no-warning --help=gen-man  > $@

$(GEN.pod):  $(SRC.pl) $(OSD.pm) $(USR.pm) $(SRC.txt)
	@$(TRACE.target)
	$(SRC.pl) --no-rc --no-warning --help=gen-pod  > $@

$(GEN.text): $(SRC.pl) $(OSD.pm) $(USR.pm) $(SRC.txt)
	@$(TRACE.target)
	$(SRC.pl) --no-rc --no-warning --help          > $@

$(GEN.wiki): $(SRC.pl) $(OSD.pm) $(USR.pm) $(SRC.txt)
	@$(TRACE.target)
	$(SRC.pl) --no-rc --no-warning --help=gen-wiki > $@

$(GEN.html): $(SRC.pl) $(OSD.pm) $(USR.pm) $(SRC.txt)
	@$(TRACE.target)
	$(SRC.pl) --no-rc --no-warning --help=gen-html > $@

$(GEN.cgi.html): $(SRC.pl) $(OSD.pm) $(USR.pm) $(SRC.txt)
	@$(TRACE.target)
	$(SRC.pl) --no-rc --no-warning --help=gen-cgi  > $@

$(GEN.inst): $(SRC.inst) Makefile
	@$(TRACE.target)
	$(EXE.install) $(SRC.inst) > $@
	chmod +x $@

$(GEN.tgz)--to-noisy: $(ALL.src)
	@$(TRACE.target)
	@grep -q '$(GREP_EDIT)' $? \
	    && echo "file(s) being edited or with invalid SID" \
	    || echo tar zcf $@ $^

# Special target to check for edited files;  it only checks the source files of
# the tool (o-saft.pl) but no other source files.
_notedit: $(SRC.exe) $(SRC.pm) $(SRC.rc) $(SRC.txt)
	@$(TRACE.target)
	@grep -q '$(GREP_EDIT)' $? \
	    && echo "file(s) being edited or with invalid SID" \
	    && exit 1 \
	    || echo "# no edits"

.PHONY: _notedit

#$(GEN.tgz): _notedit $(ALL.src)   # not working properly
#     tar: _notedit: Funktion stat failed: file or directory not found

# .tgz is tricky:  as all members should have the directory prefixed, tar needs
# to be executed in the parent directory and use $(ALL.tgz) as members.
# The target itself is called in the current directory,  hence the dependencies
# are local to that which is $(ALL.src). Note that $(ALL.tgz) is generated from
# $(ALL.src), so it contains the same members.  Executing tar in the parent dir
# would generate the tarball there also, hence the tarball is specified as full
# path with $(PWD).
# The directory prefix in the tarball is the current directory, aka $(PWD) .
$(GEN.tgz): $(ALL.src) $(GEN.tags)
	@$(TRACE.target)
	cd .. && tar zcf $(PWD)/$@ $(ALL.tgz)

$(GEN.tmptgz): $(ALL.src) $(GEN.tags)
	@$(TRACE.target)
	tar zcf $@ $^

#_____________________________________________________________________________
#__________________________________________________________ verbose targets __|

# verbose/trace command
#       TRACE.target    is the command to be used to print the target's name
#                       it is epmty by default
#       TRACE.target    can be set as environment variable, or used on command
#                       line when calling make
#                       it is also used internal for the -v targets, see below
# examples:
#  TRACE.target = echo "\# --Target: $@--"
#  TRACE.target = echo "\# --Target: $@: newer dependencies: $? --"
#  TRACE.target = echo "\# --Target: $@: all dependencies: $^ --"

# verbose targets
# NOTE: need at least one command for target execution
%-v: TRACE.target   = echo "\# $@: $?"
%-v: %
	@$(EXE.dummy)

%-vv: TRACE.target  = echo "\# $@: $^"
%-vv: %
	@$(EXE.dummy)

# the traditional way, when target-dependent variables do not work
#%-v:
#	@$(MAKE) $(MFLAGS) $(MAKEOVERRIDES) $* 'TRACE.target=echo \# $$@: $$?'
#
#%-vv:
#	@$(MAKE) $(MFLAGS) $(MAKEOVERRIDES) $* 'TRACE.target=echo \# $$@: $$^'

#_____________________________________________________________________________
#_____________________________________________ targets for testing and help __|

include $(TEST.dir)/Makefile
    # Note that $(TEST.dir)/Makefile includes all other Makefile.* there

