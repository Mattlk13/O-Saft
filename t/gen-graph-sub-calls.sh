#!/bin/sh
#?
#? NAME
#?      $0 - generate graph of subs of given perl files
#?
#? SYNOSYS
#?      $0
#?      $0 file ...
#?
#? DESCRIPTION
#?      Generates a graph for all subs and their call from given perl file.
#?      Some subs from standard libraries are removed to make result smaller.
#?
#?      Generates a complete graph and a simpler one where common verbose and
#?      trace subs are omitted.
#?
#?      Builds a graph of all found subs in following files:
#?	    o-saft_graph-sub-call-full.*
#?	    o-saft_graph-sub-call-simple.*
#?      in following formats:   DOT  graph  PDF  SVG  TCL  VCG
#?
#?      make's  e-ALL.pm  target will be used to retrieved all source files.
#?
#? OPTIONS
#?      --help  - WYSIWYG
#?      --v     - verbose output
#?      -x --x  - debug with shell's "set -x'
#?      --list  - list used source files
#?      --dir=D - generate file in directory D ; default: .
#?
#? LIMITATIONS
#?      The script generates multiple files at once. The main reason is, that
#?      the output of the initial generator graph.pl needs to be modified and
#?      then filtered before converted to other formats.
#?      Therefore use of this script may not fit into the  general concept of
#?      make which expects one result (file) for each target.
#?
#? VERSION
#?      @(#)  1.2 23/04/17 22:52:55
#?
#? AUTHOR
#?      13-mar23 Achim Hoffmann
#?
#------------------------------------------------------------------------------

#_____________________________________________________________________________
#____________________________________________________________ configuration __|

# quick tests first

if ! \command -v graph-easy 2>&1 >/dev/null ; then
	\echo "**ERROR: 'graph-easy' missing; exit"
	exit 2
fi
dot=`\command -v dot 2>/dev/null`
[ -z "$dot" ] && \echo "**ERROR: 'dot' missing; .pdf and .png not generated"

try=
ich=${0##*/}
dir=.           # directory for generated files
out=o-saft_graph-sub-call
optv=
ALL_src="`\make e-ALL.pm)` o-saft.pl"

box2ellipse="s/shape=box,/shape=ellipse,/"  # default shape should be ellipse

#_____________________________________________________________________________
#________________________________________________________________ functions __|

_vprint() {
	[ -n "$optv" ] && \echo "# $@ ..." >&2
	return
} # _vprint

#_____________________________________________________________________________
#_____________________________________________________________________ main __|

args=
while [ $# -gt 0 ]; do
	case "$1" in
	 -h | --h | --help | '-?' | '/?')
		\sed -ne "s/\$0/$ich/g" -e '/^#?/s/#?//p' $0
		exit 0
		;;
	 -n | --n) try=echo      ; ;;
	 -v | --v) optv=--v      ; ;;
	 -x | --x) set -x        ; ;;
	 --list)   \echo $ALL_src; exit 0 ;;
	 --dir=*)  dir="`expr "$1" ':' '--dir=\(.*\)'`" ; ;;
	*)      args="${args} $1"; ;;
	esac
	shift
done

if [ -n "$args" ]; then
	ALL_src=$args
fi

out_full=$dir/$out-full
out_simple=$dir/$out-simple

_vprint "ALL_src=$ALL_src ..."

# Processing all files at once with graph.pl would generate a huge graph with
# only 3-4 columns. Hence each file is processed alone, and all output used
# together in one file.
#dbx# (cd .. && t/graph.pl $ALL_src ) > $out.graph.orig
(
  for src in $ALL_src ; do
    \echo "  ( $src"
    \echo "   [$src::] {shape:rect;}"

    t/graph.pl $src | \gawk '
	# input looks like:
	#       digraph mygraph {
	#       IO__Handle__read -> croak;
	#       # many more ...
	#       }
	#
	# As the node names are without quotes, some names are invalid syntax,
	# hence they are changed to:
	#       "IO__Handle__read" -> "croak";
	#
	# The default layout mode is top-down, we want left-right, so we add:
	#       rankdir=LR
	#
	# Some subs from standard libraries are removed to make result smaller.
	#
	# graph.pl replaces :: in module names by __ ; will be reverted:
	#
	# TODO: Ausgabe von graph.pl ist sortiert: immer wenn neue Name links
	#       erscheint, einen neuen subgraph beginnen. Dann sind die subs
	#       pro Datei gruppiert.
	#
	/^ *o-saft-lib/ { next; } # same as osaft.pm
	/^ *Carp__/     { next; } # remove standard lib
	/^ *Errno__/    { next; } #
	/^ *Exporter__/ { next; } #
	/^ *IO__Handle/ { next; } #
	/^ *IO__Socket/ { next; } #
	/^ *IO__import/ { next; } #
	/^ *SelectSaver/{ next; } #
	/^ *Regexp__/   { next; } #
	/^ *Socket__/   { next; } #
	/^ *Symbol__/   { next; } #
	/^ *autouse__/  { next; } #
	/^ *base__/     { next; } #
	/^ *bytes__AUTO/{ next; } #
	/^ *constant__/ { next; } #
	/^ *overloading/{ next; } #
	/->/{
		sub(/;/,"",$3);
		gsub(/__/,"::");
		gsub(/::::/,"::__");    # subs starting with __
		sub(/_pl_MAIN/,".pl::",$1);
		sub(/_pm_MAIN/,".pm::",$1);
		#s/_MAIN /:: /g;
		printf("\t[%s] -%s [%s]\n",$1,$2,$3);   # convert to GraphiViz
		next
	}
	##{print}
	' 
    echo '  )'
  done
) \
> $out_full.graph

# we have a complete graph GraphiViz syntax, now convert to other formats
# the complete graph is very complex, so we remove some low-level functions
\sed -e /_y_CMD/d -e '/_warn\]/d' -e /_trace/d -e /_v_print/d \
	$out_full.graph > $out_simple.graph

_vprint "--------------------------------------------- generate graph for sub #}"
for _out in $out_full $out_simple ; do
	#\dot $out.graph > $out.dot             # convert DOT
	\graph-easy  $_out.graph --dot | \sed -e "$box2ellipse" > $_out.dot
	\graph-easy  $_out.graph --vcg                          > $_out.vcg
	if [ -n "$dot" ]; then
		\dot $_out.dot   -Tpdf                          > $_out.pdf
		#\dot$_out.dot   -Tpng                          > $_out.png # huge file
		\dot $_out.dot   -Tsvg                          > $_out.svg
		_vprint "# evince $_out.pdf"
		_vprint "# eog    $_out.png"
	fi
	_vprint "# xdot   $_out.dot"
done
[ -n "$optv" ] && \ls -l $dir/$out*
_vprint "---------------------------------------------------------------------#}"
exit
