#!/usr/bin/perl
## PACKAGE {

#!# Copyright (c) 2022, Achim Hoffmann
#!# This  software is licensed under GPLv2. Please see o-saft.pl for details.

package main;   # ensure that main:: variables are used

## no critic qw(ValuesAndExpressions::ProhibitCommaSeparatedStatements)
# FIXME: We have a lot of comman separated statements to simplify the code.
#        This needs to be changed in future to keep Perl::Critic happy.
#        However, the code herein is just for our own documentation ...

## no critic qw(RegularExpressions::ProhibitCaptureWithoutTest)
# NOTE:  This often happens in comma separated statements, see above.
#        It may also happen after postfix statements.
#        Need to check regularily for this problem ...

## no critic qw(RegularExpressions::ProhibitComplexRegexes)
#        Yes, we have very complex regex here.

## no critic qw(RegularExpressions::RequireExtendedFormatting)
#        We believe that most RegEx are not too complex.

## no critic qw(InputOutput::RequireBriefOpen)
#        We always close our filehandles, Perl::Critic is too stupid to read
#        over 15 lines.

## no critic qw(Documentation::RequirePodSections)
#        Perl::Critic is uses a strange list of required sections in POD.
#        See  t/.perlcriticrc .

## no critic qw(Variables::ProhibitPunctuationVar)
#        We want to use $\ $0 etc.

## no critic qw(ControlStructures::ProhibitPostfixControls  Modules::RequireVersionVar)
## no critic qw(RegularExpressions::RequireDotMatchAnything RegularExpressions::RequireLineBoundaryMatching)
## no critic qw(ValuesAndExpressions::ProhibitEmptyQuotes   RegularExpressions::ProhibitFixedStringMatches)
## no critic qw(ValuesAndExpressions::ProhibitMagicNumbers  ValuesAndExpressions::RequireUpperCaseHeredocTerminator)
## no critic qw(ValuesAndExpressions::ProhibitNoisyQuotes   )
## no critic qw(BuiltinFunctions::ProhibitBooleanGrep       BuiltinFunctions::ProhibitStringySplit)
#        Keep severity 2 silent.
# NOTE:  Modules::RequireVersionVar fails because the "no critic" pragma is to late here.

use strict;
use warnings;
use vars qw(%checks %data %text); ## no critic qw(Variables::ProhibitPackageVars)
use utf8;
# binmode(...); # inherited from parent

BEGIN {     # SEE Perl:BEGIN perlcritic
    # SEE Perl:@INC
    my $_me   = $0;     $_me   =~ s#.*[/\\]##;
    my $_path = $0;     $_path =~ s#[/\\][^/\\]*$##;
    unshift(@INC, "lib");
    unshift(@INC, $ENV{PWD}, "$ENV{PWD}/lib") if (defined $ENV{'PWD'});
    unshift(@INC, "bin");
    unshift(@INC, "lib/$_path") if ($_path ne $_me and $_path !~ m#^/#);
    unshift(@INC, $_path);
}

use osaft;
use OSaft::Doc::Data;
use OSaft::Text qw(print_pod);

my  $SID_man= "@(#) o-saft-man.pm 2.3 22/06/15 12:31:05";
my  $parent = (caller(0))[1] || "O-Saft";# filename of parent, O-Saft if no parent
    $parent =~ s:.*/::;
    $parent =~ s:\\:/:g;                # necessary for Windows only
my  $ich    = (caller(1))[1];           # tricky to get filename of myself when called from BEGIN
    $ich    = "o-saft-man.pm" if (not defined $ich); # sometimes it's empty :-((
    $ich    =~ s:.*/::;
my  $version= "$SID_man";               # version of myself
    $version=~ s:^.{5}::;               # remove leading @(#) as already part of the *.txt files
    $version=  _VERSION() if (defined &_VERSION); # or parent's if available
my  $cfg_header = 0;                    # we may be called from within parents BEGIN, hence no %cfg available
    $cfg_header = 1 if (0 < (grep{/^--header/} @ARGV));
my  $mytool = qr/(?:$parent|o-saft.tcl|o-saft|checkAllCiphers.pl)/;# regex for our tool names
my  @help   = OSaft::Doc::Data::get_markup("help.txt", $parent, $version);
local $\    = "";

# SEE Note:Stand-alone
$::osaft_standalone = 0 if not defined $::osaft_standalone; ## no critic qw(Variables::ProhibitPackageVars)

#_____________________________________________________________________________
#_________________________________________________________ internal methods __|

# SEE Perl:Undefined subroutine
*_warn = sub { print($STR{WARN}, join(" ", @_), "\n"); } if not defined &_warn;
*_hint = sub { print($STR{HINT}, join(" ", @_), "\n"); } if not defined &_hint;
*_dbx  = sub { print($STR{DBX},  join(" ", @_), "\n"); } if not defined &_dbx;

sub _get_filename   {
# TODO: move to osaft.pm or alike
    my $src = shift || "o-saft.pl";
    foreach my $dir (@INC) {    # find the proper file
        if (-e "$dir/$src") {
            $src = "$dir/$src";
            last;
        }
    }
    return $src;
} # _get_filename

sub _man_dbx        {   # similar to _y_CMD
    # When called from within parent's BEGIN{} section, options are not yet
    # parsed, and so not available in %cfg. Hence we use @ARGV to check for
    # options, which is not performant, but fast enough here.
    my @txt = @_;
    my $anf = "";
    my $end = "";
    if (0 < (grep{/^--help=gen.cgi/i} @ARGV)) {
        # debug messages should be HTML comments when generating HTML
        $anf = "<!-- "; $end = " -->";
        # TODO: need to sanitise @txt : remove <!-- and/or -->
    }
    if (0 < (grep{/^--(?:v|trace.?CMD)/i} @ARGV)) {
        print $anf . "#" . $ich . ": " . join(' ', @txt) . "$end\n";
    }
    return;
} # _man_dbx

sub _man_use_tty    {   # break long lines of text; SEE Note:tty
    # set screen width in $cfg{'tty'}->{'width'}
    _man_dbx("_man_use_tty() ...");
    return if not defined $cfg{'tty'}->{'width'};
    my $_len = 80;
    my $cols = $cfg{'tty'}->{'width'};
    if (10 > $cols) {   # size smaller 10 doesn't make sense
        $cols = $ENV{COLUMNS} || 0;  # ||0 avoids perl's "Use of uninitialized value"
        if ($cols =~ m/^[1-9][0-9]+$/) {    # ensure that we get numbers
            $cfg{'tty'}->{'width'} = $cols;
            return;
        }
        # try with tput, if it fails try with stty; errors silently ignored
        $cols = qx(\\tput cols 2>/dev/null) || undef; ## no critic qw(InputOutput::ProhibitBacktickOperators)
        if (not defined $cols) {    # tput failed or missing
            $cols =  qx(\\stty size 2>/dev/null)      ## no critic qw(InputOutput::ProhibitBacktickOperators)
                     || $_len; # default if stty fails
            $cols =~ s/^[^ ]* //;   # stty returns:  23 42  ; extract 42
        }
        $cfg{'tty'}->{'width'} = $cols;
    }
    $cfg{'tty'}->{'width'} = 80 if (10 > $cfg{'tty'}->{'width'});   # safe fallback
    _man_dbx("_man_use_tty: " . $cfg{'tty'}->{'width'});
    return;
} # _man_use_tty

sub _man_squeeze    {   # break long lines of text; SEE Note:tty
    # if len is undef, default from %cfg is used
    my $len   = shift;
    my $txt   = shift;
    return $txt if not defined $cfg{'tty'}->{'width'};
    # if a width is defined, --tty  was used
    # Keep in mind that  help.txt  is formatted to fit in 80 columns,  hence a
    # width > 80 does not change the total length of the line (which is always
    # < 80), but changes the number of left most spaces.
    $txt =~ s/[\t]/    /g;    # replace all TABs
    my $max   = $cfg{'tty'}->{'width'} - 2;     # let's have one space right
    my $ident = ' ' x $cfg{'tty'}->{'ident'};   # default ident spaces
    if (defined $len) {
        # break long lines at max size and ident remaining with len
        $ident = "$cfg{'tty'}->{'arrow'}\n" . ' ' x $len;
        $txt =~ s/(.{$max})/$1$ident/g;
    } else {
        # change left most 8 spaces to specified number of spaces
        # break long lines at max size
        # break long lines at max size and ident with specified number of spaces
        $txt =~ s/\n {8}/$ident/g;              # reduced existing identation
        $ident = "$cfg{'tty'}->{'arrow'}\n" . $ident;
        $max--;
    }
    #$max--;
    $txt =~ s/(.{$max})/$1$ident/g;             # squeeze line length
    return $txt;
} # _man_squeeze

sub _man_get_title  { return 'O - S a f t  --  OWASP - SSL advanced forensic tool'; }
sub _man_get_version{
    # ugly, but avoids global variable elsewhere or passing as argument
    no strict; ## no critic qw(TestingAndDebugging::ProhibitNoStrict)
    my $v = '2.3'; $v = _VERSION() if (defined &_VERSION);
    return $v;
} # _man_get_version

sub _man_file_get   {
    #? get filename containing text for specified keyword
    my $typ = shift;
    return OSaft::Doc::Data::get_as_text('glossary.txt')    if ('abbr'  eq $typ);
    return OSaft::Doc::Data::get_as_text('links.txt')       if ('links' eq $typ);
    return OSaft::Doc::Data::get_as_text('rfc.txt')         if ('rfc'   eq $typ);
    return '';
} # _man_file_get

sub _man_http_head  {
    #? print HTTP headers (for CGI mode)
    return if (0 >= (grep{/--cgi.?trace/} @ARGV));
    # Checking @ARGV for --cgi-trace is ok, as this option is for simulating
    # CGI mode only, in o-saft.pl SEE Note:CGI mode
    # When called from o-saft.cgi, HTTP headers are already written.
    print "X-Cite: Perl is a mess. But that's okay, because the problem space is also a mess. Larry Wall\r\n";
    print "Content-type: text/html; charset=utf-8\r\n";
    print "\r\n";
    _man_dbx("_man_http_head() ...");   # note that it must be after all HTTP headers
    return;
} # _man_http_head

sub _man_html_head  {
    #? print footer of HTML page
    # SEE HTML:JavaScript
    _man_dbx("_man_html_head() ...");
    print << 'EoHTML';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html><head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title><!-- set below --></title>
<script>
function $(id){return document.getElementById(id);}
function d(id){return $(id).style;}
function toggle_checked(id){id=$(id);id.checked=(id.checked=='false')?'true':'false';;}
function toggle_display(id){id.display=(id.display=='none')?'block':'none';}
function osaft_title(txt, ver){
        document.title      = ". : " + txt + " : .";
        $("title").title    = ver;
        $("txt").innerText  = txt;
        return;
}

function osaft_buttons(){
// generated buttons for most common commands in <table id="osaft_buttons">
        var buttons = ['+quick', '+check', '+cipher', '+cipherall', '+info', '+protocols', '+vulns' ];
        var table   = $('osaft_buttons');
        for (var b in buttons) {
                // <input type=submit name="--cmd" value="+check" ><div class=q
                // id='c+check'></div><br>
                tr = document.createElement('TR');
                td = document.createElement('TD');
                cc = document.createElement('INPUT');
                cc.type   = 'submit'; cc.name='--cmd'; cc.value=buttons[b];
                cc.title  = 'execute: o-saft.pl ' + buttons[b];
                //cc.target = 'o-saft.pl_' + buttons[b];
                td.appendChild(cc);
                tr.appendChild(td);
                td = document.createElement('TD');
                td.setAttribute('class', 'q');
                td.id='q' + buttons[b];
                tr.appendChild(td);
                table.appendChild(tr);
        }
        return;
}
function osaft_commands(){
/* get help texts from generated HTML for commands and add it to command
 * button (generated by osaft_buttons, see above) of cgi-GUI
 * existing  tag of text paragraph containing help text has  id=h+cmd
 * generated tag of  quick button  containing help text has  id=q+cmd
 */
        osaft_buttons();
        var arr = document.getElementsByTagName('p');
        for (var p=0; p<arr.length; p++) {
            if (/^h./.test(arr[p].id)===true) {
                var id = arr[p].id.replace(/^h/, 'q');
                if ($(id) != undefined) {
                    // button exists, add help text
                    $(id).innerHTML = $(arr[p].id).innerHTML;
                }
            }
        }
        return;
}
function osaft_options(){
/* get help texts from generated HTML for options and add it to option
 * checkbox of cgi-GUI (actually add it to the parent's title tag)
 * existing  tag of text paragraph containing help text has  id=h--OPT
 * generated tag of quick checkbox containing help text has  id=q--OPT
 */
        var arr = document.getElementsByTagName('p');
        for (var p=0; p<arr.length; p++) {
            if (/^h./.test(arr[p].id)===true) {
                var id = arr[p].id.replace(/^h/, 'q');
                // TODO: *ssl and *tls must use *SSL
                if ($(id) != undefined) {
                    obj = $(id).parentNode;
                    if (/^LABEL$/.test(obj.nodeName)===true) {
                        // checkbox exists, add help text to surrounding
                        // LABEL
                        obj.title = $(arr[p].id).innerHTML;
                    }
                }
            }
        }
        return;
}
function osaft_set_default(id){
/* set value of input fileds with type=text to its default (speciefied in its
 * attribute osaft-default)
 */
        var obj = document.getElementById(id);
        try { obj.value = obj.getAttribute('osaft-default'); } catch(e) {}
        return;
}
function osaft_enable(){
/* check all input fileds with type=text if they are disabled, which is set by
 * see osaft_submit(), then remove the disabled attribute again
 */
        var arr = document.getElementsByTagName('input');
        for (var tag=0; tag<arr.length; tag++) {
            if (/^text$/.test(arr[tag].type)===true) {
                arr[tag].removeAttribute('disabled');
            }
        }
        return;
}
function osaft_submit(){
/* check all input fileds with type=text if the value differs from its default
 * adds the attribute disabled to the input tag to ensure that no name=value
 * for this input field will be submitted
 * return true (so that the form will be submitted)
 */
        var arr = document.getElementsByTagName('input');
        for (var tag=0; tag<arr.length; tag++) {
            if (/^text$/.test(arr[tag].type)===true) {
                if (arr[tag].value === arr[tag].getAttribute('osaft-default')) {
                    arr[tag].setAttribute('disabled', true);
                }
            }
        }
        // ensure that input fields are enabled again
        setTimeout("osaft_enable()",2000);
        return true;
}
function osaft_handler(from,to){
/* set form's action and a's href attribute if schema is file:
 * replace all href attributes also to new schema
 */
        var rex = new RegExp(from.replace(/\//g, '.'),"");  // lazy convertion to Regex
        var url = document.forms["o-saft"].action;          // in case we need it
        if (/^file:/.test(location.protocol)===false) { return false; } // not a file: schema
        var arr = document.getElementsByTagName('form');
        for (var tag=0; tag<arr.length; tag++) {
            if (rex.test(arr[tag].action)===true) {
                arr[tag].action = arr[tag].action.replace(rex, to).replace(/^file:/, 'osaft:');
            }
        }
        //dbx// alert(document.forms["o-saft"].action);
        var arr = document.getElementsByTagName('a');
        for (var tag=0; tag<arr.length; tag++) {
            if (rex.test(arr[tag].href)===true) {
                arr[tag].href = arr[tag].href.replace(rex, to).replace(/^file:/, 'osaft:');
            }
        }
        return false;
}
function osaft_disable_help(){
// disable help-buttons
        return;  // -- NOT YET WORKING --
        var arr = document.getElementsByTagName('a');
        for (var p=0; p<arr.length; p++) {
            if (arr[p].className==="b") {
                arr[p].setAttribute('disabled', true);  // not working
                arr[p].setAttribute('display', 'none'); // not working
                //arr[p].disabled = true;  // not working
                //alert(arr[p].href+" "+arr[p].display);
            }
        }
        return;
}
function schema_is_file(){
        if (/^file:/.test(location.protocol)===true) { return true; }
        return false;
}
function toggle_handler(){
// toggle display of "schema" button
        if (schema_is_file()===true) { return; }
        toggle_display(d("schema"));
        return;
}
</script>
<style>
  /* variable definitions */
  :root {
    /* color and background */
    --bg-osaft:     #fff;
    --bg-blue:      #226;               /* darkblue  */
    --bg-head:      linear-gradient(#000,#fff);    /* black,white */
    --bg-mbox:      rgba(0,0,0,0.9);
    --bg-mdiv:      linear-gradient(#fff,#226);
    --bg-button:    linear-gradient(#d3d3d3,#fff);  /* lightgray */
    --bg-start:     linear-gradient(#ffd700,#ff0);  /* gold */
    --bg-start-h:   linear-gradient(#ff0,#ffd700);  /* gold */
    --bg-hover:     #d3d3d3;            /* lightgray */
    --bg-literal:   #d3d3d3;            /* lightgray */
    --border-0:     0px solid #fff;
    --border-1:     1px solid #080;     /* green */
    --border-w:     1px solid #fff;     /* white */
  }
 .h             {margin-left:     1em;border:var(--border-0);}
 .l             {margin-left:     2em;}
 .r             {float:right;}
 .b, div[class=h] > a, input[type=submit] {
                 margin:        0.1em;padding:0px 0.5em 0px 0.5em; text-decoration:none; font-weight:bold; color:#000; border:var(--border-1); border-radius:2px; box-shadow:1px 1px 3px #666; background:var(--bg-button);}
 a[class="b r"]:hover, div[class=h] > a:hover {background:var(--bg-button);}
 p > a[class="b"] {margin-left: -2em; }
 p > a[class="b"]:hover         {background:var(--bg-button);}
 .c             {padding:0px 3px 0px 3px;            border:var(--border-0);font-size:12pt !important; font-family:monospace;background:var(--bg-literal);} /* white-space:pro */
 .q             {border:var(--border-0);}
 p              {margin-left:     2em;margin-top:0;}
 td             {                     padding-left:    1em;}
 h2             {margin:       -0.3em;margin-bottom: 0.5em;height:1.5em;padding:1em;background:var(--bg-head);color:white;border-radius:0px 0px 20px 20px;box-shadow:0 5px 5px #c0c0c0; }
 h3, h4, h5     {margin-bottom: 0.2em;}
 body > h2      {margin-top:   -0.5em;padding:  1em; height:1.5em;background-color:black;color:white;}
 body > h4      {margin-left:     1em;}
 b              {margin-left:     1em;}     /* for discrete commands */
 li             {margin-left:     3em;}
 li.n           {list-style-type: none; }
 div            {                     padding:0.5em; border:var(--border-1);}
 div[class=c]   {margin-left:     4em;padding:0.1em; border:var(--border-0);}
 div[class=n]   {                                    border:var(--border-0);}
 form           {font-size:       20px; }   /* chromium hack */
 form           {                     padding:1em;}
 span           {margin-bottom:   2em;font-size:120%;border:var(--border-1);}
 h2 > span      {                                    border:var(--border-0);}
 label[class=i] {margin-right:    1em;min-width:8em; border:var(--border-w);display:inline-block;}
 label[class=i]:hover           {background:var(--bg-hover);border-bottom:var(--border-1);}
 input[type=submit]             {background:var(--bg-start);min-width:8em;text-align:left;}
 input[type=submit]:hover       {background:var(--bg-start-h);}
 input          {margin-right:  0.5em;}
 fieldset > p   {margin:           0px;padding:0.5em;background-color:#ffa;}
 /* dirty hack for mobile-friendly A tag's title= attribute;
  * placed left bound below tag; browser's title still visible
  * does not work for BUTTON and INPUT tags
  */
 [title]        {position:  relative; }
 a[class=b][title]:hover:after, a[class='b r'][title]:hover:after {
    content: attr(title);
    position:absolute; z-index:99; top:100%; left:-1em;
    border: 2px solid darkgrey; border-radius:2px;
    background-color:rgba(0,0,0,0.8); color:white;
    font-weight:normal; padding:0.3em; }
</style>
</head>
<body>
 <h2 id="title" title="" ><span id="txt" ></span>
     <button id="schema" style="float: right;" onclick="osaft_handler(osaft_action_http,osaft_action_file);" title="change schema of all&#13;action and href attributes">Change to osaft: schema</button>
 </h2>
 <!-- also hides unwanted text before <body> tag -->
EoHTML
    # TODO: need <input name=cgi value="/path/to/o-saft.cgi" />
    return;
} # _man_html_head

sub _man_html_warn  {
    #? print "Note" text box for CGI usage; only visible with fragment #Note
    _man_dbx("_man_html_warn() ...");
    print << 'EoHTML';
 <style>
  /* message box "Note", if necessary # TODO: font-size not working in firefox */
  .m            {opacity:1; pointer-events:none; position:fixed; transition:opacity 400ms ease-in; background:var(--bg-mbox); top:0; right:0; bottom:0; left:0; z-index:9; }
  .m > div      {position:relative; width:35em; margin:13% auto; padding:1em; border-radius:8px;   background:var(--bg-mdiv); font-size:150%; }
  .m > div > p  {font-size:120%; }
  .m > div > a  {opacity:1; pointer-events:auto; }
  .m > div > a  {position:absolute; width:1.1em; top:0.1em;      right:0.2em; line-height:1.1em;   background:var(--bg-blue); color:#fff; text-align:center;  text-decoration:none; font-weight:bold; border-radius:8px; box-shadow:1px 3px 3px #5bb; }
  .m > div > a:hover  {background: #5bb; }
  .m > div > h3       {margin:-0.8em; border-bottom:var(--border-1); margin-bottom:1em; }
  .m > div > h3:before{content:"\00a0\00a0\00a0" }
 </style>
 <div id="warn" class="m"> <div>
  <a  id="seen" href="" onclick="toggle_display(d('warn'));return false;" title="I understand">X</a>
  <h3>O-Saft as CGI </h3>
  <p>This is a sample implementation to show O-Saft's functionality.</p>
  <p>It is not intended to be used for regular tests of foreign servers.</p>
  <p>The server may be slow and is short on memory, so please don't expect miracles.</p>
 </div> </div>
EoHTML
    return;
} # _man_html_warn

sub _man_help_button{
    #? return href tag for a help button
    my $url   = shift;
    my $cmd   = shift;      # must be --help=* option; also used for button text
    my $class = shift;      # value for class= attribute (if not empty)
    my $title = shift;      # value for title= attribute
    my $txt   = $cmd;       # 
       $txt  =~ s/^--//;    # button text without --help
       $txt  =~ s/^help=//; # button text without --help
       $class = "class='$class'" if ($class !~ m/^\s*$/);
    return sprintf('<a %s href="%s?--cgi&--header&%s" target=_help title="%s" >%s</a>', $class, $url, $cmd, $title, $txt);
} # _man_help_button

sub _man_form_head  {
    #? print start of CGI form
    my $cgi_bin = shift;
    _man_dbx("_man_form_head() ...");
    printf(" <div class=h ><b>Help:</b>\n");
    printf("  <a class='b r' href='o-saft.html' target=_help  title='open window with complete help (rendered)'> ? </a>\n");
    printf("  %s\n", _man_help_button($cgi_bin, "--help",         'b', "open window with complete help (plain text)"));
    printf("  %s\n", _man_help_button($cgi_bin, "--help=command", 'b', "open window with help for commands"));
    printf("  %s\n", _man_help_button($cgi_bin, "--help=checks",  'b', "open window with help for checks"));
    printf("  %s\n", _man_help_button($cgi_bin, "--help=example", 'b', "open window with examples"));
    printf("  %s\n", _man_help_button($cgi_bin, "--help=opt",     'b', "open window with help for options"));
    printf("  %s\n", _man_help_button($cgi_bin, "--help=FAQ",     'b', "open window with FAQs"));
    printf("  %s\n", _man_help_button($cgi_bin, "--help=abbr",    'b', "open window with the glossar"));
    printf("  %s\n", _man_help_button($cgi_bin, "--help=todo",    'b', "open window with help for ToDO"));
    print << "EoHTML";
 </div>
 <form id="o-saft" action="$cgi_bin" method="GET" onsubmit="return osaft_submit()" target="cmd" >
  <noscript><div>
JavaScript disabled. The buttons for most common commands are missing.<br>
The buttons "Commands & Options", "Full GUI" and "Simple GUI" will not work.<br>
All options with values are passed to $cgi_bin .
  </div><br></noscript>
  <input  type=hidden name="--cgi" value="" >
  <fieldset>
    <p>
    Hostname: <input type=text name="--url"  size=40 title='hostname or hostname:port or URL' >
    <input  type=submit name="--cmd" value="+check" title="execute: o-saft.pl +check ..." onclick='this.value="+check";' >
    </p>
    <table id="osaft_buttons">
    </table><br>
    <input type=reset  value="clear" title="clear all settings or reset to defaults"/>
    <button onclick="toggle_display(d('a'));return false;" title="show options">Commands & Options</button>
    <div id="a" >
        <button class=r onclick="toggle_display(d('a'));toggle_display(d('b'));return false;" title="switch to full GUI with all\ncommands and options and their description">Full GUI</button>
    <br>
      <div class=n>
EoHTML
        # Above HTML contains <div class=n> which contains checkboxes for some
        # options. These checkboxes are added in following  foreach loop.
        # Above HTML contains  <table id="osaft_buttons">  which contains the
        # quick buttons for some commands. These quick buttons should get the
        # description from the later generated help text in this page,  hence
        # the buttons are not generated here but using  JavaScript at runtime
        # so that the corresponding help text  can be derived from the (HTML)
        # page itself. SEE HTML:JavaScript
    #foreach my $key (qw(cmd cmd cmd cmd)) { print _man_html_cmd($key); }
    # show most common used options; layout by lines using BR
    foreach my $key (qw(no-sslv2 no-sslv3 no-tlsv1 no-tlsv11 no-tlsv12 no-tlsv13 BR
                     no-dns dns no-cert BR
                     no-sni sni   BR
                     no-http http BR
                     header  no-header  no-warnings format=html   BR
                     enabled disabled   legacy=owasp BR
                     traceKEY traceCMD  trace v     cgi-no-header BR
                 )) {
        if ('BR' eq $key) { print "        <br>\n"; next; }
        my $tag_nam = '--' . $key;
        print _man_html_cbox('cgi', "        ", "q$tag_nam", $tag_nam, "", $tag_nam) . "\n";
    }
    print _man_html_go("cgi");
    print << "EoHTML";
      </div><!-- class=n -->
    </div><!-- id="a" -->
    <div id="b" >
        <button class=r onclick="d('a').display='block';d('b').display='none';return false;" title="switch to simple GUI\nwith most common options only">Simple GUI</button><br>
        <!-- not yet working properly
        <input type=text     name=--cmds size=55 title="type any command or option"/>/>
        -->
EoHTML
    return;
} # _man_form_head

sub _man_form_foot  {
    #? print end of CGI form
    my $cgi_bin = shift;
    _man_dbx("_man_form_foot() ...");
    print << "EoHTML";
</p>
        <input type=reset  value="clear" title="clear all settings or reset to defaults"/>
        <button class=r onclick="d('a').display='block';d('b').display='none';return false;" title="switch to simple GUI\nwith most common options only">Simple GUI</button><br>
    </div><!-- id="b" -->
  </fieldset>
 </form>
 <hr>
 <script>
  var osaft_action_http="$cgi_bin"; // default action used in FORM and A tags; see osaft_handler()
  var osaft_action_file="/o-saft.cgi";         // default action used if file: ; see osaft_handler()
  osaft_commands("a");              // generate quick buttons
  osaft_options();                  // generate title for quick options
  d("a").display="none";            // hide
  d("b").display="none";            // hide
  toggle_handler();                 // show "change schema" button if file:
  toggle_checked("q--header");      // want nice output
  toggle_checked("q--enabled");     // avoid huge cipher lists
  toggle_checked("q--no-tlsv13");   // most likely not yet implemented
  toggle_checked("o--header");      // .. also as option ..
  toggle_checked("o--enabled");     // .. also as option ..
  toggle_checked("o--no-tlsv13");   // .. also as option ..
 </script>
EoHTML
    return;
} # _man_form_foot

sub _man_html_foot  {
    #? print footer of HTML page
    _man_dbx("_man_html_foot() ...");
    my $title   = _man_get_title();
    my $vers    = _man_get_version();
    print << "EoHTML";
 <a href="https://github.com/OWASP/O-Saft/"   target=_github >Repository</a> &nbsp;
 <a href="https://github.com/OWASP/O-Saft/blob/master/o-saft.tgz" target=_tar class=b >Download (stable)</a>
 <a href="https://github.com/OWASP/O-Saft/archive/master.zip" target=_tar class=b >Download (newest)</a><br><br>
 <a href="https://owasp.org/www-project-o-saft/" target=_owasp  >O-Saft Home</a>
 <hr><p><span style="display:none">&copy; Achim Hoffmann 2022</span></p>
 <script>
  osaft_title("$title", "$vers");
  if (schema_is_file()===true) { osaft_disable_help(); }
 </script>
</body></html>
EoHTML
    return;
} # _man_html_foot

sub _man_html_cbox  {   ## no critic qw(Subroutines::ProhibitManyArgs)
    #? return input checkbox tag with clickable label and hover highlight
    my ($mode, $prefix, $tag_id, $tag_nam, $tag_val, $cmd_txt) = @_;
    my $title = '';
       $title = 'experimental option' if ("--format=html" eq $cmd_txt); # TODO: experimental hack
    return $cmd_txt if ($mode ne 'cgi');        # for "html" nothing special
    return sprintf("%s<label class=i for='%s'><input type=checkbox id='%s' name='%s' value='%s' title='%s' >%s</label>&#160;&#160;",
        $prefix, $tag_id, $tag_id, $tag_nam, $tag_val, $title, $cmd_txt);
} # _man_html_cbox

sub _man_html_chck  {
    #? return checkbox, or input field with clickable label (to reset input)
    #? to beused for +commands and --options
    my $mode    = shift; # cgi or html
    my $cmd_opt = shift || "";                  # +cmd or --opt or --opt=value
    my $tag_nam = $cmd_opt;
    my $tag_val = '';
    return '' if ($cmd_opt !~ m/^(?:-|\+)+/);   # defensive programming
    return $cmd_opt if ($mode ne 'cgi');        # for "html" nothing special
    # $cmd_opt may contain:  "--opt1 --opt2"; hence split at spaces and use first
    if ($cmd_opt =~ m/^(?:\+)/) { # is command, print simple checkbox
        $tag_val =  scalar((split(/\s+/, $cmd_opt))[0]);
        $tag_nam =  '--cmd';
    } else { # is optionm print simple checkbox or input field
        # options are  --opt  or  --opt=VALUE;  SEE HTML:INPUT
        $tag_val =  '';                         # checkbox with empty value
        $tag_nam =  scalar((split(/\s+/, $cmd_opt))[0]);
        my ($key, $val) = split(/=/, $tag_nam); # split into key and value
        if (defined $val && $val =~ m/^[A-Z0-9:_-]+/) { # --opt=VALUE
            my $label = sprintf("<label class=l onclick=osaft_set_default('%s'); title='click resets to default value'>%s=</label>", $tag_nam, $key);
            my $input = sprintf("<input type=text id='%s' name='%s' value='%s' osaft-default='%s'>", $tag_nam, $key, $val, $val);
            return "$label$input";
        # else: see below
        }
    }
    return _man_html_cbox($mode, "", "o$cmd_opt", $tag_nam, $tag_val, $cmd_opt);
} # _man_html_chck

sub _man_name_ankor {
    my $n = shift;
    $n =~ s/,//g;  # remove comma
    #$n =~ s/\s/_/g;# replace spaces
    return $n;
} # _man_name_ankor

sub _man_html_ankor {
    #? return ankor tag for each word in given parameter
    my $n = shift;
    my $a = '';
    return sprintf('<a name="a%s"></a>', $n) if ($n !~ m/^[-\+]+/);
    foreach my $n (split(/[\s,]+/,$n)) {
        $a .= sprintf("<a name='a%s'></a>", _man_name_ankor($n));
    }
    return $a;
} # _man_html_ankor

sub _man_html_go    {
    #? return button "Top" and button "start"
    # SEE HTML:start
    my $key = shift;
    return "" if ($key ne 'cgi');
    my $top = sprintf("%8s<a class=b href='#aCOMMANDS' title='return to Commands'>^</a>\n", "");
    my $run = sprintf("%8s<input type=submit value='start' title='execute o-saft.pl with selected commands and options'/>\n", "");
    return "$top$run";
} # _man_html_go

sub _man_html_cmds  {
    #? return checkboxes for commands not found in help.txt but are generated dynamically
    my $key = shift;
    my $txt = "";
    my $cmds= _man_cmd_from_source(); # get all command from %data and %check_*
    # $cmds.= _man_cmd_from_rcfile(); # RC-FILE not used here
    _man_dbx("_man_html_cmds($key) ...");
    foreach my $cmd (split(/[\r\n]/, $cmds)) {
        next if ($cmd =~ m/^\s*$/);
        $cmd =~ s/^\s*//;
        if ($cmd =~ m/^[+]/) {
            my $desc = "";
            ($cmd, $desc) = split(/\s+/, $cmd, 2);
            $txt .= sprintf("<b>%s </b> %s<br />\n", _man_html_cbox($key, "", "c$cmd", "--cmd", $cmd, $cmd), $desc);
                # TODO: <b> should be <h4>, but as h4 is a display:block tag,
                #   the remainig text $desc would be rendered in a new line;
                #   to avoid this, a <span> with proper CSS needs to be used
        } else {
            $txt .= _man_html_go($key) . "\n";
            $txt .= sprintf("%s\n<h3>%s</h3>\n", _man_html_ankor($cmd), $cmd);
        }
    }
    #print "## $txt ##"; exit;
    return $txt;
} # _man_html_cmds

sub _man_html       {   ## no critic qw(Subroutines::ProhibitExcessComplexity)
    #? print text in HTML format
    my $key = shift;    # cgi or html
    my $url = shift;    # URL
    my $anf = shift;    # pattern where to start extraction
    my $end = shift;    # pattern where to stop extraction
    my $skip= 0;
    my $c   = 0;
    my $h   = 0;
    my $a   = "";       # NOTE: Perl::Critic is scary, SEE Perlcritic:LocalVars
    my $p   = "";       # for closing p Tag
    _man_dbx("_man_html($key, $anf, $end) ...");
    while ($_ = shift @help) {
        # NOTE: sequence of following m// and s/// is important
        # FIXME: need  s!<<!&lt;&lt;!g; before any print
        last if/^TODO/;
        $h=1 if/^=head1 $anf/;
        $h=0 if/^=head1 $end/;
        next if (0 == $h);                          # ignore "out of scope"
        if (0 < $skip) { $skip--; next; }           # skip some texts
        # TODO: does not work:      <p onclick='toggle_display(this);return false;'>\n",
        m/^=head1 (.*)/   && do {
                    printf("$p\n<h1>%s %s </h1>\n", _man_html_ankor($1),$1);
                    $p="";
                    next;
                };
        m/^=head2 (.*)/   && do {
                    my $x=$1;
                    if ($x =~ m/Discrete commands to test/) {
                        # SEE Help:Syntax
                        # command used for +info and +check have no description in @help
                        print _man_html_cmds($key); # extract commands from dource code
                    } else {
                        print _man_html_go($key);
                        print _man_html_ankor($x) . "\n";
                        printf("<h3>%s %s </h3> <p>\n", _man_html_chck($key,$x), $x );
                    }
                    next;
                };
        m/^=head3 (.*)/   && do {
                    # commands and options expected with =head3 only
                    $a=$1; ## no critic qw(Variables::RequireLocalizedPunctuationVars)
                    if ('cgi' eq $key) {
                        print _man_help_button($url, $a, "b r", "open window with special help") if ($a =~ m/--help/);
                    }
                    print _man_html_ankor($a) . "\n";
                    printf("<h4>%s </h4> <p>\n", _man_html_chck($key,$a));
                    next;
                };
        m/Discrete commands,/ && do { $skip=2; next; }; # skip next 3 lines; SEE Help:Syntax
        # encode special markup
        m/(--help=[A-Za-z0-9_.-]+)/ && do {         # add button for own help (must be first in sequence)
                    if ('cgi' eq $key) {
                        print _man_help_button($url, $1, "b r", "open window with special help");
                    }
                };
        m/^\s*S&([^&]*)&/ && do {
                    # code or example line
                    my $v=$1;
                    $v=~s!<<!&lt;&lt;!g;
                    print "<div class=c >$v</div>\n";
                    next
                };
        s!'([^']*)'!<span class=c >$1</span>!g;     # markup examples
        s!"([^"]*)"!<cite>$1</cite>!g;              # markup examples
        #dbx# m/-SSL/ && do { print STDERR "##1 $_ ###"; };
        m![IX]&(?:[^&]*)&! && do {
                    # avoid spaces in internal links to anchors
                    # FIXME: dirty hack, probably bug in get_markup()
                    s/\s+&/&/g;                     # trim trailing spaces
                };
        s!I&([^&]*)&!<a href="#a$1">$1</a>!g;       # markup commands and options
        s!X&([^&]*)&!<a href="#a$1">$1</a>!g;       # markup references inside help
        s!L&([^&]*)&!<i>$1</i>!g;                   # markup other references
            # L& must be done after I& ad/or X& to avoid mismatch to i.e.  I&-SSL&
        s!^\s+($mytool .*)!<div class=c >$1</div>!; # example line
        # detect lists, very lazy ... # SEE HTML:Known Bugs
        m/^=item +\* (.*)/&& do { print "<li>$1</li>\n";next;};
        m/^=item +\*\* (.*)/  && do{ print "<li type=square style='margin-left:3em'>$1 </li>\n";next;};
        s/^(?:=[^ ]+ )//;                           # remove remaining markup
        s!<<!&lt;&lt;!g;                            # encode special markup
        # add paragraph for formatting, SEE HTML:p and HTML:JavaScript
        m/^\s*$/ && do { ## no critic qw(Variables::RequireLocalizedPunctuationVars)
                    $a = "id='h$a'" if ('' ne $a);
                    print "$p<p $a>";
                    $p = "</p>";
                    $a = '';
                }; # SEE Perlcritic:LocalVars
        s!(^ {12}.*)!<li class="n">$1</li>!;        # 12 spaces are used in lists, mainly
        print;
    }
    print "$p"; # if not empty, otherwise harmless
    return;
} # _man_html

sub _man_head       {   ## no critic qw(Subroutines::RequireArgUnpacking)
    #? print table header line (dashes)
    my $len1 = shift;   # this line triggers Perl::Critic, stupid :-/
    my @args = @_;      # .. hence "no critic" pragma above
    _man_dbx("_man_head(..) ...");
    return if (1 > $cfg_header);
    my $len0 = $len1 - 1;
    printf("=%${len0}s | %s\n", @args);
    printf("=%s+%s\n", '-'x  $len1, '-'x60);
    return;
} # _man_head

sub _man_foot       {
    #? print table footer line (dashes)
    my $len1 = shift;   # expected length of first (left) string
    return if (1 > $cfg_header);
    printf("=%s+%s\n", '-'x $len1, '-'x60);
    return;
} # _man_foot

sub _man_opt        {   ## no critic qw(Subroutines::RequireArgUnpacking)
    #? print line in  "KEY - VALUE"  format
    my @args = @_; # key, sep, value
    my $len  = 16;
       $len  = 1 if ($args[1] eq "="); # allign left for copy&paste
    my $txt  = sprintf("%${len}s%s%s\n", @args);
    print _man_squeeze((16+length($_[1])), $txt);
    return;
} # _man_opt

sub _man_cfg        {
    #? print line in configuration format
    my ($typ, $key, $sep, $txt) = @_;
    $txt =  '"' . $txt . '"' if ($typ =~ m/^cfg(?!_cmd)/);
    $key =  "--$typ=$key"    if ($typ =~ m/^cfg/);
    _man_opt($key, $sep, $txt);
    return;
} # _man_cfg

sub _man_txt        {
    #? print text configuration format (replaces \n\r\t )
    my ($typ, $key, $sep, $txt) = @_;
    $txt =~ s/(\n)/\\n/g;
    $txt =~ s/(\r)/\\r/g;
    $txt =~ s/(\t)/\\t/g;
    _man_cfg($typ, $key, $sep, $txt);
    return;
} # _man_txt

sub _man_pod_item   {
    #? print line as POD =item
    my $line = shift;
    print "=over\n\n$line\n=back\n";
    return;
} # _man_pod_item

sub _man_usr_value  {
    #? return value of argument $_[0] from @{$cfg{'usr_args'}}
    # expecting something like  usr-action=/some.cgi  in $cfg{'usr_args'}
    my $key =  shift;
       $key =~ s/^(?:--|\+)//;  # strip leading chars
    my @arg =  '';              # key, value # Note: value is anything right to leftmost = 
    map({@arg = split(/=/, $_, 2) if /^$key/} @{$cfg{'usr_args'}}); # does not allow multiple $key in 'usr_args'
    return $arg[1];
} # _man_usr_value

sub _man_doc_opt    {
    #? print text from file $typ in  "KEY - VALUE"  format
    #  type is:   abbr, links, rfc
    #  format is: opt, POD
    my ($typ, $sep, $format) = @_;  # format is POD or opt
    my  $url  = '';
    my  @txt  = _man_file_get($typ);
    # OSaft::Doc::*::get()  returns one line for each term;  format is:
    #   term followd by TAB (aka \t) followed by description text
    foreach my $line (@txt) {
        chomp  $line;
        next if ($line =~ m/^\s*$/);
        next if ($line =~ m/^\s*#/);
        my ($key, $val) = split("\t", $line);
            $key =~ s/\s*$//;
        if ('rfc' eq $typ) {    # RFC is different, adapt $key and $val
            $url = $val if ($key eq "url"); # should be first line only
            $val = $val . "\n\t\t\t$url/html/rfc$key";
            $key = "RFC $key";
        }
        _man_opt($key, $sep, $val)          if ('opt' eq $format);
        _man_pod_item("$key $sep $val\n")   if ('POD' eq $format);
    }
    return;
} # _man_doc_opt

sub _man_doc_pod    {
    #? print text from file $typ in  POD  format
    my ($typ, $sep) = @_;
    my  @txt  = _man_file_get($typ);
    # print comment lines only, hence add # to each line
    my  $help = "@txt";
        $help =~ s/\n/\n#/g;
    print "# begin $typ\n\n";
    print "# =head1 $typ\n\n";
    print $help;
    #_man_doc_opt($typ, $sep, "POD");   # if real POD should be printed
    print "# end $typ\n";
    return;
} # _man_doc_pod

sub _man_pod_head   {
    #? print start of POD format
    print <<'EoHelp';
#!/usr/bin/env perldoc
#?
# Generated by o-saft.pl .
# Unfortunately the format in  @help is incomplete,  for example proper  =over
# and corresponding =back  paragraph is missing. It is mandatory around  =item
# paragraphs. However, to avoid tools complaining about that,  =over and =back
# are added to each  =item  to avoid error messages in the viewer tools.
# Hence the additional identations for text following the =item are missing.
# Tested viewers: podviewer, perldoc, pod2usage, tkpod

EoHelp
    print "=pod\n\n=encoding utf8\n\n"; # SEE POD:Syntax
    return;
} # _man_pod_head

sub _man_pod_text   {
    #? print text in POD format
    my $code  = 0;  # 1 if last printed line was `source code' format
    my $empty = 0;  # 1 if last printed line was empty
    while ($_ = shift @help) {          # @help already looks like POD
        last if m/^(?:=head[1] )?END\s+#/;# very last line in this file
        m/^$/ && do {  ## no critic qw(RegularExpressions::ProhibitFixedStringMatches)
            if (0 == $empty)  { print; $empty++; }  # empty line, but only one
            next;
        };
        s/^(\s*(?:o-saft\.|checkAll|yeast\.).*)/S&$1&/; # dirty hack; adjust with 14 spaces
        s/^ {1,13}//;                   # remove leftmost spaces (they are invalid for POD); 14 and more spaces indicate a line with code or example
        s/^S&\s*([^&]*)&/\t$1/ && do {  # code or example line
            print "\n" if (0 == ($empty + $code));
            print; $empty = 0; $code++; next;   # no more changes
        };
        $code = 0;
        s:['`]([^']*)':C<$1>:g;         # markup literal text; # dumm '
        s:(^|\s)X&([^&]*)&:$1L</$2>:g;  # markup references inside help
        s:(^|\s)L&([^&]*)&:$1L<$2|$2>:g;# markup other references
        #s:L<[^(]*(\([^\)]*\)\>).*:>:g; # POD does not like section in link
        s:(^|\s)I&([^&]*)&:$1I<$2>:g;   # markup commands and options
        s/^([A-Z., -]+)$/B<$1>/;        # bold
        s/^(=item)\s+(.*)/$1 $2/;       # squeeze spaces
        my $line = $_;
        m/^=/ && do {                   # paragraph line
            # each paragraph line must be surrounded by empty lines
            # =item paragraph must be inside =over .. =back
            print "\n"        if (0 == $empty);
            print "$line"     if $line =~ m/^=[hovbefpc].*/;# any POD keyword
            _man_pod_item "$line" if $line =~ m/^=item/;    # POD =item keyword
            print "\n";
            $empty = 1;
            next;
        };
        print "$line";
        $empty = 0;
    }
    return;
} # _man_pod_text

sub _man_pod_foot   {
    #? print end of POD format
    print <<'EoHelp';
Generated with:

        o-saft.pl --no-warnings --no-header --help=gen-pod > o-saft.pod

EoHelp
    print "=cut\n\n";           # SEE POD:Syntax
    _man_doc_pod('abbr', "-");  # this is for voodoo, see below
    _man_doc_pod('rfc',  "-");  # this is for voodoo, see below
    print <<'EoHelp';

# begin voodoo

# Some documentation is plain text, which is  DATA  in Perl sources. As such,
# it  is  not detected as source,  not as comment,  and  not as documentation
# by most tools analyzing the source code.
# O-Saft's public user documentation is plain text stored in  separate files.
# The files are  usually also not counted as source.
# Unfortunately, some people solely believe in statistics generated by  magic
# tools. They use such statistics to measure for example code quality without
# looking themself at the code.
# Hence the purpose of this file is to provide real comment and documentation
# lines from our documentation in format of the used programming language.
# Hopefully, if these people read this, they change the workflow (means: they
# also review the source code) or adapt their conclusions having in mind that
# statistics can be manipulated in many ways. Here we go ...
#
# Disclaimer: No offence meant anyhow, neither against any analyzing tool nor
# against anyone using them. It is just a reminder to use the tools and their
# results in a wise manner. Measuring quality is more than just automatically
# generated statistics!

# end voodoo

EoHelp
    return;
} # _man_pod_foot

sub _man_wiki_head  {
    #? print start of mediawiki format
    print <<'EoHelp';
==O-Saft==
This is O-Saft's documentation as you get with:
 o-saft.pl --help
<small>On Windows following must be used
 o-saft.pl --help --v
</small>

__TOC__ <!-- autonumbering is ugly here, but can only be switched of by changing MediaWiki:Common.css -->
<!-- position left is no good as the list is too big and then overlaps some texts
{|align=right
 |<div>__TOC__</div>
 |}
-->

[[Category:OWASP Project]]  [[Category:OWASP_Builders]]  [[Category:OWASP_Defenders]]  [[Category:OWASP_Tool]]  [[Category:SSL]]  [[Category:Test]]
----
EoHelp
    return;
} # _man_wiki_head

sub _man_wiki_text  {
    #? print text of mediawiki format
    #  convert POD syntax to mediawiki syntax
    my $mode =  shift;
    while ($_ = shift @help) {
        last if/^=head1 TODO/;
        s/^=head1 (.*)/====$1====/;
        s/^=head2 (.*)/=====$1=====/;
        s/^=head3 (.*)/======$1======/;
        s/^=item (\*\* .*)/$1/;         # list item, second level
        s/^=item (\* .*)/$1/;           # list item, first level
        s/^=[^= ]+ *//;                 # remove remaining markup and leading spaces
        print, next if/^=/;             # no more changes in header lines
        s:['`]([^']*)':<code>$1</code>:g;  # markup examples # dumm '
        s/^S&([^&]*)&/  $1/ && do { print; next; }; # code or example line; no more changes
        s/X&([^&]*)&/[[#$1|$1]]/g;      # markup references inside help
        s/L&([^&]*)&/\'\'$1\'\'/g;      # markup other references
        s/I&([^&]*)&/\'\'$1\'\'/g;      # markup commands and options
        s/^ +//;                        # remove leftmost spaces (they are useless in wiki)
        if ('colon' eq $mode) {
            s/^([^=].*)/:$1/;           # ident all lines for better readability
        } else {
            s/^([^=*].*)/:$1/;          # ...
        }
        s/^:?\s*($mytool)/  $1/;        # myself becomes wiki code line
        s/^:\s+$/\n/;                   # remove empty lines
        print;
    }
    return;
} # _man_wiki_text

sub _man_wiki_foot  {
    #? print end of mediawiki format
    print <<'EoHelp';
----
<small>
Content of this wiki page generated with:
 o-saft.pl --no-warning --no-header --help=gen-wiki
</small>

EoHelp
    return;
} # _man_wiki_foot

sub _man_cmd_from_source {
    #? return all command from %data and %check_*
    my $txt  = "";
    my $skip = 1;
    my $fh   = undef;
    if (open($fh, '<:encoding(UTF-8)', _get_filename("o-saft.pl"))) { # need full path for $parent file here
        # TODO: o-saft.pl hardcoded, need a better method to identify the proper file
        while(<$fh>) {
            # find start of data structure
            # all structure look like:
            #    our %check_some = ( # description
            #          'key' => {... 'txt' => "description of value"},
            #    );
            # where we extract the description of the checked class from first
            # line and the command and its description from the data lines
            if (m/^(?:my|our)\s+%(?:check_(?:[a-z0-9_]+)|data)\s*=\s*\(\s*##*\s*(.*)/) {
                $skip = 0;
                $txt .= "\n                  Commands to show results of checked $1\n";
                next;
            }
            $skip = 1, next if (m/^\s*\)\s*;/); # find end of data structure
            next if (1 == $skip);
            next if (m/^\s*'(?:SSLv2|SSLv3|D?TLSv1|TLSv11|TLSv12|TLSv13)-/); # skip internal counter
            if (m/^\s+'([^']*)'.*"([^"]*)"/) {
                my $key = $1;
                my $val = $2;
                my $len = "%-17s";
                   $len = "%s " if (length($key) > 16); # ensure that there is at least one space
                my $t   = "\t";
               #   $t  .= "\t" if (length($1) < 7);
                $txt .= sprintf("+$len%s\n", $1, $2);
            }
        }
        close($fh); ## no critic qw(InputOutput::RequireCheckedClose)
    }
    return $txt;
} # _man_cmd_from_source

sub _man_cmd_from_rcfile {
    #? return all command RC-FILE
    my $txt  = "\n                  Commands locally defined in $cfg{'RC-FILE'}\n";
    my $val  = "";
    my $skip = 1;
    my $fh   = undef;
    if (open($fh, '<:encoding(UTF-8)', $cfg{'RC-FILE'})) {
        # TODO: need a better method to identify the proper file, RC-FILE is
        #       wrong when this file was called directly
        while(<$fh>) {
            if (m/^##[?]\s+([a-zA-Z].*)/) { # looks like:  ##? Some text here ...
                $skip = 0;
                $val  = $1;
                next;
            }
            if (m/^--cfg_cmd=([^=]*)=/) {   # looks like:  --cfg_cmd=MyCommad=list items
                next if (1 == $skip);   # continue only if previous match succedded
                $skip = 1;
                $txt .= sprintf("+%-17s%s\n", $1, $val);
                $val  = "";
            }
        }
        close($fh); ## no critic qw(InputOutput::RequireCheckedClose)
    }
    return $txt;
} # _man_cmd_from_rcfile

#_____________________________________________________________________________
#__________________________________________________________________ methods __|

sub man_help_brief  {
    #? print overview of help commands (invoked with --h)
    # TODO: get this data from internal data structure when it is ready ...
    # extract all --help= options with their description from @help
    # using a foreach loop instead of regex to avoid memory polution
    _man_dbx("man_help_brief() ...");
    my %opts;
    my $skip  = 1;
    my $idx   = 0;  # perl hashes are sorted randomly, we want to keep the sequence in @help
    my $key   = "";
    foreach my $line (@help) {  # note: @help is in POD format
        # we expect somthing like:
        #    =head2 Options for help and documentation
        #    =head3 --help=cmds
        #
        #          Show available commands; short form.
        #
        #    ...
        #
        $skip = 1 if ($line =~ m/^=head2\s+Options for /);
        $skip = 0 if ($line =~ m/^=head2\s+Options for help/);
        next      if ($line =~ m/^=head2\s+Options for help/);
        next if (1 == $skip);
        next if ($line =~ m/^\s*$/);
        chomp $line;
        #_dbx "$line" if $skip == 0;
        if ($line =~ m/^=head3\s+--h/) {    # --h and --help and --help=*
            $idx++;
            $key  = $line;
            $key  =~ s/^=head3\s+//;
            $opts{$idx}->{'opt'} = $key;
            next;
        }
        $line =~ s/^\s*//;                  # normalise
        $line =~ s![IX]&([^&]*)&!$1!g;      # remove markup
        $line =  sprintf("\n%17s %s", " ", $line) if (defined $opts{$idx}->{'txt'});
        $opts{$idx}->{'txt'} .= $line;
    }
    print "\n";
    _man_head(15, "Option", "Description");
    foreach my $key (sort {$a <=> $b} keys %opts) {
        printf("%-17s %s\n", $opts{$key}->{'opt'}, $opts{$key}->{'txt'}||"");
    }
    _man_foot(15);
    print "\n";
    _man_head(15, "Command", "Description");
    print <<"EoHelp";
+info             Overview of most important details of the SSL connection.
+cipher           Check target for ciphers (using libssl).
+check            Check the SSL connection for security issues.
+protocols        Check for protocols supported by target.
+vulns            Check for various vulnerabilities.
EoHelp
    _man_foot(15);
    my $opt = "";
       $opt = " --header" if (0 < $cfg_header); # be nice to the user
    printf("\nFor more options  see: $cfg{me}$opt --help=opt");
    printf("\nFor more commands see: $cfg{me}$opt --help=commands\n\n");
    return;
} # man_help_brief

sub man_commands    {
    #? print commands and short description
    # data is extracted from $parents internal data structure
    _man_dbx("man_commands($parent) ...");
    # first print general commands, manually crafted here
    # TODO needs to be computed, somehow ...
    # SEE Help:Syntax
    print "\n";
    _man_head(15, "Command", "Description");
    my $txt = <<"EoHelp";
                  Commands for information about this tool
+dump             Dumps internal data for SSL connection and target certificate.
+exec             Internal command; should not be used directly.
+help             Complete documentation.
+list             Show all ciphers supported by this tool.
+libversion       Show version of openssl.
+quit             Show internal data and exit, used for debugging only.
+VERSION          Just show version and exit.
+version          Show version information for program and Perl modules.

                  Commands to check SSL details
+bsi              Various checks according BSI TR-02102-2 and TR-03116-4 compliance.
+check            Check the SSL connection for security issues.
+check_sni        Check for Server Name Indication (SNI) usage.
+ev               Various checks according certificate's extended Validation (EV).
+http             Perform HTTP checks.
+info             Overview of most important details of the SSL connection.
+info--v          More detailled overview.
+quick            Quick overview of checks.
+protocols        Check for protocols supported by target.
+s_client         Dump data retrieved from  "openssl s_client ..."  call.
+sizes            Check length, size and count of some values in the certificate.
+sni              Check for Server Name Indication (SNI) usage.
+sts              Various checks according STS HTTP header.
+vulns            Check for various vulnerabilities.

                  Commands to test ciphers provided by target
+cipher           Check target for ciphers (using libssl).
+cipher-dh        Check target for ciphers (using libssl), prints also DH parameter.
+cipherall        Check target for all possible ciphers (same format as +cipher).
+cipherraw        Check target for all possible ciphers (special format).
+cipher-default   Check target for (default) selected cipher for each protocol.
+cipher-null      Check if target accepts NULL ciphers.
+cipher-adh       Check if target accepts ciphers with anonymous key exchange.
+cipher-exp       Check if target accepts EXPORT ciphers.
+cipher-cbc       Check if target accepts CBC ciphers.
+cipher-des       Check if target accepts DES ciphers.
+cipher-rc4       Check if target accepts RC4 ciphers.
+cipher-edh       Check if target supports ephemeral ciphers.
+cipher-pfs       Check if target supports ciphers with PFS.
+cipher-strong    Check if target selects strongest cipher.
+cipher-selected  Selected cipher.

EoHelp

    print _man_squeeze(18, $txt);

    print _man_squeeze(18,_man_cmd_from_source());
    print _man_cmd_from_rcfile();
    _man_foot(15);
    print "\n";
    return;
} # man_commands

sub man_warnings    {
    #? print warning messages defined in code
    #? recommended usage:   $0 --header --help=warnings
    # data is extracted from separate file, which could be created by make
    _man_dbx("man_warnings($parent) ...");
    my $txt  = "";
    my $rex  = '.STR\{(?:ERROR|WARN|HINT)},|' . join('|', $STR{ERROR}, $STR{WARN}, $STR{HINT});
       $rex  =~ s/([*!])/\\$1/g;# escape meta chars in text
       $rex  = qr($rex);        # match our own messages only
    my $fh   = undef;
    my $doc  = 'docs/o-saft.pl.--help=warnings';
        # file generated by: "make doc.data", which calls "make warnings-info"
        # TODO: need some kind of configuration for the filename
    _man_dbx("man_warnings: rex=$rex");
    if (not open($fh, '<:encoding(UTF-8)', $doc)) {
        _warn("091:", "help file '$doc' cannot be opened: $! ; ignored");
        _hint($cfg{'hints'}->{'help=warnings'});
        return;
    } # else
    # parse file and collect messages from there, print warnings while parsing
    # first,  otherwise it is difficult (for human readers) to distinguish the
    # collected messages from the warning messages printed while parsing; also
    # note that Perl's  warn()  and not  our own  _warn()  is used, because it
    # prints the line number from the read file,  which contains the line with
    # unknown/unexpected syntax
    # following formats of a line are expected:
    #       **WARNING: 042: text ..."    -- _warn() called with only one parameter
    #       **WARNING: 091:", "text ..." -- _warn() called with two parameters
    #       print $STR{WARN}, "text ..."  -- print used to print message
    #dbx# _dbx("rex $rex\n");
    while(<$fh>) {
        next if (m/^\s*#/);
        next if (m/^\s*$/);
        if (not m/$rex/) {
            warn($STR{WARN}, "092:", " help file '$doc' unknown syntax: '$_' ; ignored"); ## no critic qw(ErrorHandling::RequireCarping)
            next;
        }
        my ($err, $nr, $msg)  = m/($rex\s*)"?([0-9]{3}:?)(.*)/;
        my  $bad = 0;
            $bad = 1 if (not defined $err or $err =~ m/^$/);
            $bad = 1 if (not defined $nr  or $nr  =~ m/^$/);
            $bad = 1 if (not defined $msg or $msg =~ m/^$/);
        if ($bad == 1) {
             # unexpected format, silently print and continue
             #dbx# _dbx("bad $_");
             $txt .= sprintf("%s", $_);
             next;
        }
        $err =~ s/\$STR\{ERROR}/$STR{ERROR}/;
        $err =~ s/\$STR\{WARN}/$STR{WARN}/;
        $err =~ s/, *//;
        $msg =~ s/^[", ]*//;
        $txt .= sprintf("%s%s\t- %s\n", $err, $nr, $msg);
    }
    close($fh); ## no critic qw(InputOutput::RequireCheckedClose)
    # print collected messages
    print <<"EoHelp";

=== Warning and error messages ===

= Messages numbers and texts used in $cfg{'me'} and its own modules.
= Note that message texts may contain variables, like '\$key', which are
=      replaced with propper texts at runtime.

# TODO: some missing, i.e. 002: 003: 004:

EoHelp
    _man_head(15, "Error/Warning", "Message text");
    print $txt;
    _man_foot(15);
    # TODO: return if (($cfg{'out'}->{'warning'} + $cfg{'out'}->{'hint'}) < 2);
    return;
} # man_warnings

sub man_table       {   ## no critic qw(Subroutines::ProhibitExcessComplexity)
    #? print data from hash in tabular form, $typ denotes hash
    #? header of table is not printed if $typ is cfg-*
    #  NOTE critic: McCabe 22 (tested 5/2016) is not that bad here ;-)
    my $typ = shift;# NOTE: lazy matches against $typ below, take care with future changes
       $typ =~ s/^cipher(pattern|range)/$1/;# normalise: cipherrange and range are possible
    my %types = (
        # typ        header left    separator  header right
        #-----------+---------------+-------+-------------------------------
        'score' => ["key",           " - ",  " SCORE\t# Description"],
        'regex' => ["key",           " - ",  " Regular Expressions used internally"],
        'ourstr'=> ["key",           " - ",  " Regular Expressions to match own output"],
        'abbr'  => ["Abbrevation",   " - ",  " Description"],
        'intern'=> ["Command",       "    ", " list of commands"],
        'compl' => ["Compliance",    " - ",  " Brief description of performed checks"],
        'range' => ["range name",    " - ",  " hex values in this range"],
        'pattern' =>["pattern name", " - ",  " pattern description; used pattern"],
        'rfc'   => ["Number",        " - ",  " RFC Title and URL"],
        'links' => ["Title",         " - ",  " URL"],
        'check' => ["key",           " - ",  " Label text"],
        'data'  => ["key",           " - ",  " Label text"],
        'hint'  => ["key",           " - ",  " Hint text"],
        'text'  => ["key",           " - ",  " text"],
        'cmd'   => ["key",           " - ",  " list of commands"],
    );
    my $txt = "";
    my $sep = "\t";
    if (defined $types{$typ}) { # defensive programming
       $sep = $types{$typ}->[1];
    } else {
       if ($typ =~ m/(?:^cfg[_-]|[_-]cfg$)/) {
           # the purpose of cfg_* is to print the results in a format so that
           # they can be used with copy&paste as command-line arguments
           # simply change the separator to =  while other headers are unused
           # (because no header printed at all)
           $sep = "=" if ($typ =~ m/(?:^cfg[_-]|[_-]cfg$)/);
       } else {
           # this is a programming error, hence always printed on STDERR
           print STDERR "**WARNING: 510: unknown table type '$typ'; using 'text' instead.\n";
           return; # avoid uninitialised value; return as no data for $typ is available
       }
    }
    _man_dbx("man_table($typ) ...");
    _man_head(16, $types{$typ}->[0], $types{$typ}->[2]) if ($typ !~ m/^cfg/);

    # first only lists, which cannot be redefined with --cfg-*= (doesn't make sense)

    _man_doc_opt($typ, $sep, 'opt');    # abbr, rfc, links, ...
    # return; 

    if ($typ eq 'compl') { _man_opt($_, $sep, $cfg{'compliance'}->{$_})    foreach (sort keys %{$cfg{'compliance'}}); }

    if ($typ eq 'intern') {
        # first list command with all internal commands_*
        foreach my $key (sort keys %cfg) {
            next if ($key !~ m/^commands_(?:.*)/);
            _man_opt($key, $sep, "+" . join(' +', @{$cfg{$key}}));
        }
        foreach my $key (sort keys %cfg) {
            next if ($key !~ m/^cmd-(.*)/);
            _man_opt("cmd-" . $1, $sep, "+" . join(' +', @{$cfg{$key}}));
        }
    }

    # now all lists, which can be redefined with --cfg-*=
    # _man_cfg() prints different data for  --help=TYP and --help=TYP-cfg
    if ($typ =~ m/(hint|ourstr|pattern|range|regex)/) {
        my $list = $1;
           $list =~ s/^cfg[._-]?//;
           $list =~ s/[._-]?cfg$//;
           $list =  'hints' if ($list =~ m/hint/);  # the key in %cfg is 'hints'; 'hint' is different
           $list =  'cipherpatterns' if ($list =~ m/pattern/);
           $list =  'cipherranges'   if ($list =~ m/range/);
        # TODO: --cfg_range=* and --cfg-regex=*  are not yet implemented
        #       however, we can print it using --help=cfg-regex
        foreach my $key (sort keys %{$cfg{$list}}) {
            $txt =  $cfg{$list}->{$key};
            if ('ARRAY' eq ref($cfg{$list}->{$key})) {
                $txt = join("\t", @{$cfg{$list}->{$key}});
            }
            _man_cfg($typ, $key, $sep, $txt);
        }
    }
    if ($typ =~ m/cmd/) {
        foreach my $key (sort keys %cfg) {
            next if ($key !~ m/^cmd-/);
            next if ($key =~ m/^cmd-(?:check|info)/); # FIXME: currently disabled
            $txt =  $cfg{$key};
            if ('ARRAY' eq ref($cfg{$key})) {
                $txt = join(" ", @{$cfg{$key}});
            }
            $key =~ s/^cmd.// if ($typ =~ m/cfg/);
                # $key in %cfg looks like  cmd-sni, but when configuring the
                # key in RC-FILE it looks like  --cfg_cmd=sni=   ...
            _man_cfg($typ, $key, $sep, $txt);
        }
    }
    if ($typ =~ m/score/) {
        foreach my $key (sort keys %checks) {
            $txt =  $checks{$key}->{score} . "\t# " . $checks{$key}->{txt};
            $txt =  $checks{$key}->{score} if ($typ =~ m/cfg/);
            _man_cfg($typ, $key, $sep, $txt);
        }
    }
    if ($typ =~ m/check/) {
        foreach my $key (sort keys %checks) {
            $txt =  $checks{$key}->{txt};
            _man_cfg($typ, $key, $sep, $txt);
        }
    }
    if ($typ =~ m/(?:data|info)/) {
        foreach my $key (sort keys %data) {
            $txt =  $data{$key}->{txt};
            _man_cfg($typ, $key, $sep, $txt);
        }
    }
    if ($typ =~ m/text/) {
        foreach my $key (sort keys %text) {
#_dbx "$key : " . ref($text{$key});
            if ('' eq ref($text{$key})) {   # string
                $txt =  $text{$key};
                _man_txt($typ, $key, $sep, $txt);
            }
            if ('HASH' eq ref($text{$key})) {
                # TODO: not yet printed, as it may confuse the user
                #foreach my $k (sort keys $text{$key}) {
                #    $txt =  $text{$key}->{$k};
                #    _man_txt($typ, "$key($k)", $sep, $txt);
                #}
            }
        }
    }
    if ($typ !~ m/cfg/) {
        _man_foot(16);
    } else {
        # additional message here is like a WARNING or Hint,
        # do not print it if any of them is disabled
        return if (($cfg{'out'}->{'warning'} + $cfg{'out'}->{'hint'}) < 2);
        print <<"EoHelp";
= Format is:  KEY=TEXT ; NL, CR and TAB are printed as \\n, \\r and \\t
= (Don't be confused about multiple  =  as they are part of  TEXT.)
= The string  @@  inside texts is used as placeholder.
= NOTE: " are not escaped!

EoHelp
    }
    return;
} # man_table

sub man_alias       {
    #? print alias and short description (if available)
    #
    # Aliases are extracted from the source code. All lines handling aliases
    # for commands or options are marked with the pattern  # alias:
    # From these lines we extract the regex, the real option or command and
    # the comment.
    #
    #                 /------- regex -------\         /--- command ----\  /pattern\ /--- comment ---
    # Examples of lines to match:
    #    if ($arg eq  '--nosslnodataeqnocipher'){$arg='--nodatanocipher';} # alias:
    #    if ($arg =~ /^--ca(?:cert(?:ificate)?)$/i)  { $arg = '--cafile';} # alias: curl, openssl, wget, ...
    #    if ($arg =~ /^--cadirectory$/i)     { $arg = '--capath';        } # alias: curl, openssl, wget, ...
    #    if ($arg eq  '-c')                  { $arg = '--capath';        } # alias: ssldiagnose.exe
    #   #if ($arg eq  '--protocol')          { $arg = '--SSL';           } # alias: ssldiagnose.exe
    #
    print "\n";
    _man_head(27, "Alias (regex)         ", "command or option   # used by ...");
    my $txt =  "";
    my $fh  = undef;
    my $p   = '[._-]'; # regex for separators as used in o-saft.pl
    if (open($fh, '<:encoding(UTF-8)', _get_filename("o-saft.pl"))) { # need full path for $parent file here
        # TODO: o-saft.pl hardcoded, need a better method to identify the proper file
        while(<$fh>) {
            next if (not m(# alias:));
            next if (not m|^\s*#?if[^/']*.([^/']+).[^/']+.([^/']+).[^#]*#\s*alias:\s*(.*)?|);
            my $commt =  $3;
            my $alias =  $2;
            my $regex =  $1;
            # simplify regex for better (human) readability
            $regex =~ s/^\^//;      # remove leading ^
            $regex =~ s/^\\//;      # remove leading \
            $regex =~ s/\$$//;      # remove trailing $
            $regex =~ s/\(\?:/(/g;  # remove ?: in all groups
            $regex =~ s/\[\+\]/+/g; # replace [+] with +
            $regex =~ s/\$p\?/-/g;  # replace variable
            # check if alias is command or option
            if ($alias !~ m/^[+-]/) {
                # look not like command or option, use comment
                $alias = $commt if ($commt =~ m/^[+-]/);
            }
            if (29 > length($regex)) {
                $txt = sprintf("%-29s%-21s# %s\n", $regex, $alias, $commt);
            } else {
                # pretty print if regex is to large for first column
                $txt  = sprintf("%s\n", $regex);
                $txt .= sprintf("%-29s%-21s# %s\n", "", $alias, $commt);
            }
            print _man_squeeze(29, $txt);
        }
        close($fh); ## no critic qw(InputOutput::RequireCheckedClose)
    }
    _man_foot(27);
    print <<'EoHelp';
= Note for names in  Alias  column:
=   For option names  - or _ characters are not shown, they are stripped anyway.
=   For command names - or _ characters are also possible, but only - is shown.

EoHelp
    return;
} # man_alias

sub man_toc         {
    #? print help table of contents
    my $typ     = lc(shift) || "";      # || to avoid uninitialised value
    _man_dbx("man_toc() ..");
    foreach my $txt (grep{/^=head. /} @help) {  # note: @help is in POD format
        next if ($txt !~ m/^=head/);
        next if ($txt =~ m/^=head. *END/);  # skip last line
        if ($typ =~ m/cfg/) {
            $txt =~ s/^=head1 *(.*)/{print "--help=$1\n"}/e;
        } else {
            # print =head1 and =head2
            # just =head1 is lame, =head1 and =head2 and =head3 is too much
            $txt =~ s/^=head([12]) *(.*)/{print "  " x $1, $2,"\n"}/e; # use number from =head as ident
        }
        # TODO:  _man_squeeze(6, $txt); # not really necessary
    }
    return;
} # man_toc

sub man_pod         {
    #? print complete POD page for o-saft.pl --help=gen-pod
    _man_dbx("man_pod() ...");
    _man_pod_head();
    _man_pod_text();
    _man_pod_foot();
    return;
} # man_pod

sub man_man         {
    #? print complete MAN page for o-saft.pl --help=gen-man
    # executable  pod2man is used instead of Pod::Man, mainly because Pod::Man
    # can only read from STDIN or a file, but input here for Pod::Man may come
    # from variables; 
    _man_dbx("man_man() ...");
    my $pod = "o-saft.pod";         # TODO: dirty hack to find proper .pod file
       $pod = "docs/o-saft.pod"     if (! -e $pod);
       $pod = "../docs/o-saft.pod"  if (! -e $pod);
    exec("pod2man --name=o-saft.pl --center='OWASP - SSL advanced forensic tool' --utf8 $pod" );
    # return;
} # man_man

sub man_html        {
    #? print complete HTML page for o-saft.pl --help=gen-html
    #? recommended usage:   $0 --no-warning --no-header --help=gen-html
    # for concept and functionality of the generated page  SEE HTML:HTML
    _man_dbx("man_html() ...");
    _man_http_head();
    _man_html_head();
    _man_html('html', '', 'NAME', 'TODO');  # print complete help
    _man_html_foot();
    return;
} # man_html

sub man_cgi         {
    #? print complete HTML page for o-saft.pl used as CGI
    #? recommended usage:      $0 --no-warning --no-header --help=gen-cgi
    #?    o-saft.cgi?--cgi=&--usr&--no-warning&--no-header=&--cmd=html
    # for concept and functionality of the generated page  SEE HTML:CGI
    #
    # <a href="$cgi_bin?--cgi&--help=html"    target=_help >help (HTML format)</a>
    # previous link not generated because it prints multiple HTTP headers
    #
    # <from action= > and <a href= > values (link) must be specified using the
    # option  --usr-action=  at script start.
    #
    my $cgi_bin = _man_usr_value('user-action') || _man_usr_value('usr-action') || "/cgi-bin/o-saft.cgi";
        # get action from --usr-action= or set to default (defensive programming)
    _man_dbx("man_cgi() ...");
    _man_http_head();
    _man_html_head();
    _man_form_head(  $cgi_bin);
    _man_html('cgi', $cgi_bin, 'COMMANDS', 'LAZY'); # print help starting at COMMANDS
    _man_form_foot(  $cgi_bin);
    _man_html_warn();   # not exactly the place in HTML for this <div>, but syntactically ok
    _man_html_foot();
    # TODO: osaft_action_http, osaft_action_file should be set dynamically
    return;
} # man_cgi

sub man_wiki        {
    #? print documentation for o-saft.pl in mediawiki format (to be used at owasp.org until 2019)
    #? recommended usage:   $0 --no-warning --no-header --help=gen-wiki
    my $mode =  shift;
        # currently only mode=colon is implemented to print  :*  instead of *
        # Up to VERSION 15.12.15 list items * and ** where printed without
        # leading : (colon). Some versions of mediawiki did not support :*
        # so we can switch this behavior now.
    _man_dbx("man_wiki($mode) ...");
    _man_wiki_head();
    _man_wiki_text($mode);
    _man_wiki_foot();
    return;
} # man_wiki

sub man_help        {
    #? print complete user documentation for o-saft.pl as plain text (man-style)
    my $label   = lc(shift) || "";      # || to avoid uninitialised value
    my $anf     = uc($label);
    my $end     = "[A-Z]";
    _man_dbx("man_help($anf, $end) ...");
    # no special help, print full one or parts of it
    if (0 < $::osaft_standalone) {  ## no critic qw(Variables::ProhibitPackageVars)
        # FIXME dirty hack
        @help   = OSaft::Doc::Data::get_markup("help.txt", $parent, $version) if not @help;
    }
    my $txt = join ('', @help);
        # = OSaft::Doc::Data::get("help.txt", $parent, $version);
    if (1 < (grep{/^--v/} @ARGV)) {     # with --v --v
        print OSaft::Doc::Data::get_egg("help.txt");
        return;
    }
    if ($label =~ m/^name/i)    { $end = "TODO";  }
    #$txt =~ s{.*?(=head. $anf.*?)\n=head. $end.*}{$1}ms;# grep all data
        # above terrible performance and unreliable, hence in peaces below
    $txt =~ s/.*?\n=head1 $anf//ms;
    $txt =~ s/\n=head1 $end.*//ms;      # grep all data
    $txt = "\n=head1 $anf" . $txt;
    $txt =~ s/\n=head2 ([^\n]*)/\n    $1/msg;
    $txt =~ s/\n=head3 ([^\n]*)/\n      $1/msg;
    $txt =~ s/\n=(?:[^ ]+ (?:\* )?)([^\n]*)/\n$1/msg;# remove inserted markup
    $txt =~ s/\nS&([^&]*)&/\n$1/g;
    $txt =~ s/[IX]&([^&]*)&/$1/g;       # internal links without markup
    $txt =~ s/L&([^&]*)&/"$1"/g;        # external links, must be last one
    $txt =  _man_squeeze(undef, $txt);
    if (0 < (grep{/^--v/} @ARGV)) {     # do not use $^O but our own option
        # some systems are tooo stupid to print strings > 32k, i.e. cmd.exe
        print "**WARNING: using workaround to print large strings.\n\n";
        print foreach split(//, $txt);  # print character by character :-((
    } else {
        print $txt;
    }
    if ($label =~ m/^todo/i)    {
        print "\n  NOT YET IMPLEMENTED\n";
        foreach my $label (sort keys %checks) {
            next if (0 >= _is_member($label, \@{$cfg{'commands_notyet'}}));
            print "        $label\t- " . $checks{$label}->{txt} . "\n";
        }
    }
    return;
} # man_help

sub src_grep        {
    #? search for given text in source file, then pretty print
    my $hlp = shift;
    print "\n";
    _man_head(14, "Option    ", "Description where program terminates");
    my $fh  = undef;
    if (open($fh, '<:encoding(UTF-8)', _get_filename("o-saft.pl"))) { # need full path for $parent file here
        # TODO: o-saft.pl hardcoded, need a better method to identify the proper file
        while(<$fh>) {
            next if (m(^\s*#));
            next if (not m(_(?:EXIT|NEXT).*$hlp));
            my $opt     = $_;
            my $comment = $_;
            if ($opt =~ m/exit=/) {
                # line looks like: _yeast_EXIT("exit=BEGIN0 - BEGIN start");
                # or             : _yeast_NEXT("exit=HOST0 - host start");
                $opt =~ s/^[^"]*"/--/;    $opt =~ s/ - .*$//s;
                $comment =~ s/^[^-]*//; $comment =~ s/".*$//s;
            }
            printf("%-15s%s\n", $opt, $comment);
        }
        close($fh); ## no critic qw(InputOutput::RequireCheckedClose)
    }
    _man_foot(14);
    return;
} # src_grep

sub printhelp       {   ## no critic qw(Subroutines::ProhibitExcessComplexity)
    #? simple dispatcher for various help requests
    #  NOTE critic: as said: *this code is a simple dispatcher*, that's it
    my $hlp = shift;
    _man_dbx("printhelp($hlp) ...");
    _man_use_tty();
    # NOTE: some lower case strings are special
    man_help('NAME'),           return if ($hlp =~ /^$/);           ## no critic qw(RegularExpressions::ProhibitFixedStringMatches)
    man_help('TODO'),           return if ($hlp =~ /^todo$/i);      ## no critic qw(RegularExpressions::ProhibitFixedStringMatches)
    man_help('KNOWN PROBLEMS'), return if ($hlp =~ /^(err(?:or)?|problem)s?$/i);
    if ($hlp =~ /^faq/i) {
        man_help('KNOWN PROBLEMS');
        man_help('LIMITATIONS');
        return
    }
    man_help($hlp),             return if ($hlp =~ /^(?:CHECKS?|CUSTOM)$/); # not case-sensitive!
        # NOTE: bad design, as we have headlines in the documentation which
        #       are also used as spezial meaning (see below). In particular
        #       CHECKS  is a  headline for a section  in the documentation,
        #       while  checks  is used to print the labels of performed all
        #       checks. Workaround is to treat all-uppercase words as head-
        #       line of a section and anything else as special meaning.
        # However, note that  --help=check  already behaves the same way as
        # --help=CHECKS  while  --help=check  prints the labels. Means that
        # this special condition (match CHECKS) is just for commodity.
    man_toc($1),                return if ($hlp =~ /^((?:toc|content)(?:.cfg)?)/i);
    man_html(),                 return if ($hlp =~ /^(gen-)?html$/);
    man_wiki('colon'),          return if ($hlp =~ /^(gen-)?wiki$/);
    man_pod(),                  return if ($hlp =~ /^(gen-)?pod$/i);
    man_man(),                  return if ($hlp =~ /^(gen-)?man$/i);
    man_man(),                  return if ($hlp =~ /^(gen-)?[nt]roff$/i);
    man_cgi(),                  return if ($hlp =~ /^(gen-)?cgi$/i);
    man_alias(),                return if ($hlp =~ /^alias(es)?$/);
    man_commands(),             return if ($hlp =~ /^commands?$/);
    return man_warnings()              if ($hlp =~ /^warnings?$/);
    return man_help_brief()            if ($hlp =~ /^help_brief$/); # --h
    # anything below requires data defined in parent
    man_table('rfc'),           return if ($hlp =~ /^rfcs?$/);
    man_table('links'),         return if ($hlp =~ /^links?$/);
    man_table('abbr'),          return if ($hlp =~ /^(abbr|abk|glossary?)$/);
    man_table('compl'),         return if ($hlp =~ /^compliance$/i);# alias
    man_table(lc($1)),          return if ($hlp =~ /^(intern|compl|pattern)s?$/i);
    man_table(lc($1)),          return if ($hlp =~ /^(cipher(?:pattern|range)?)s?$/i);
    man_table(lc($1)),          return if ($hlp =~ /^(cmd|check|data|info|hint|text|range|regex|score|ourstr)$/i);
    man_table('cfg_'.lc($1)),   return if ($hlp =~ /^(cmd|check|data|info|hint|text|range|regex|score|ourstr)[_-]?cfg$/i);
    man_table('cfg_'.lc($1)),   return if ($hlp =~ /^cfg[_-]?(cmd|check|data|info|hint|text|range|regex|score|ourstr)s?$/i);
        # we allow:  text-cfg, text_cfg, cfg-text and cfg_text so that
        # we can simply switch from  --help=text  and/or  --cfg_text=*
        # we do not allow --help=cfg-cmds or --help=cfg-checks due to conflict
        #    with --help=cmds (see next condiftion);  since 19.01.19
    if ($hlp =~ /^cmds$/i)      { # print program's commands
        # no need for _man_squeeze()
        print "# $parent commands:\t+"     . join(' +', @{$cfg{'commands'}});
        return;
    }
    if ($hlp =~ /^legacys?$/i)  { # print program's legacy options
        # no need for _man_squeeze()
        print "# $parent legacy values:\t" . join(' ',  @{$cfg{'legacys'}});
        return;
    }
    if ($hlp =~ /^help$/) {
        #my $hlp = OSaft::Doc::Data::get("help.txt", $parent, $version); # already in @help
        my $txt  = "";
        foreach (@help) { $txt .= $_ if (m/Options for help and documentation/..m/Options for all commands/); };
            # TODO: quick&dirty match against to fixed strings (=head lines)
        $txt =~ s/^=head.//msg;
        $txt =~ s/Options for all commands.*.//msg;
        print _man_squeeze(undef, $txt);
        #man_help('Options for help and documentation');
        return;
    }
    if ($hlp =~ m/^opts?$/i)    { # print program's options
        my @txt  = grep{/^=head. (General|Option|--)/} @help;   # get options only
        foreach my $line (@txt) { $line =~ s/^=head. *//}       # remove leading markup
        my($end) = grep{$txt[$_] =~ /^Options vs./} 0..$#txt;   # find end of OPTIONS section
        print join('', "OPTIONS\n", splice(@txt, 0, $end));     # print anything before end
        # no need for _man_squeeze()
        return;
    }
    if ($hlp =~ m/^Tools$/i) {    # description for O-Saft tools
        my @txt = OSaft::Doc::Data::get("tools.txt", $parent, $version);
        #print _man_squeeze(undef, "@txt"); # TODO: does not work well here
        print @txt;
        return;
    }
    if ($hlp =~ m/^Program.?Code$/i) { # print Program Code description
        my @txt = OSaft::Doc::Data::get("coding.txt", $parent, $version);
        #print _man_squeeze(undef, "@txt"); # TODO: does not work well here
        print @txt;
        return;
    }
    src_grep("exit="),          return if ($hlp =~ /^exit$/i);
    # nothing matched so far, try to find special section and only print that
    _man_dbx("printhelp: " . uc($hlp));
    man_help(uc($hlp));
    return;
} # printhelp

sub _main_man       {   # needs not to be _main unless used as Perl package
    my $arg = shift || "--help";    # without argument print own help
    ## no critic qw(InputOutput::RequireEncodingWithUTF8Layer)
    #  SEE Perl:binmode()
    binmode(STDOUT, ":unix:utf8");
    binmode(STDERR, ":unix:utf8");
    print_pod($0, __FILE__, $SID_man) if ($arg =~ m/--?h(elp)?$/x);  # print own help
    # else
    $arg =  $ARGV[0];
    $arg =~ s/--help[_.=-]?//;  # allow --help=* and simply *
    $arg =~ s/--test[_.=-]?//;  # allow --test-* also,
        # testing this module is technically the same as getting the text
    printhelp($arg);
    exit 0;
} # _main_man

sub o_saft_man_done {};     # dummy to check successful include

#_____________________________________________________________________________
#_____________________________________________________ public documentation __|

=pod

=encoding utf8


=head1 NAME

o-saft-man.pm - Perl module to handle O-Saft's documentation


=head1 DESCRIPTION

This module provides functionality to generate O-Saft's user documentation
in various formats. Supported formats are:

=over 2

=item * POD

=item * *roff (man page)

=item * HTML

=item * mediawiki

=item * Plain Text

=back

Additionally various parts of the  documentation can be generated.  Please
see  L<METHODS>  below.


=head1 SYNOPSIS

=over 2

=item * require q{o-saft-man.pm}; printhelp($format); # in Perl code

=item * o-saft-man.pm --help        # on command-line will print help

=item * o-saft-man.pm [<$format>]   # on command-line

=back

For compatibility with other programs and modules it also supports:

=over 2

=item * o-saft-man.pm --help=<$format>

=item * o-saft-man.pm --test-<$format>

=back


=head1 METHODS

=over 2

=item * printhelp($format)

Public method for  all functionality.  The generated output format depends
on the $format parameter, which is a literal string, as follows:

=over 2

=item * pod     -> all documentation in POD format

=item * man     -> all documentation in MAN (nroff) format

=item * html    -> all documentation in HTML format

=item * wiki    -> all documentation in mediawiki format

=item * NAME    -> all documentation in plain text (man-style) format

=item * <empty>

=item * NAME    -> all documentation in plain text (man-style) format

=item * contents

=item * toc     -> table of contents for documentation as plain text

=item * help    -> list all options to get (help) information

=item * cgi     -> all documentation as HTML for CGI usage

=item * alias   -> list of all aliases for commands and options

=item * cmds    -> list of all commands (just the commands)

=item * command -> list of all commands with brief description

=item * opts    -> list of all options (just the options)

=item * options -> list of all options with full description

=item * legacy  -> list of legacy options

=item * checks  -> list of all SSL/TLS checks (each can be used as command)

=item * data    -> list of all SSL/TLS data values (each can be used as command)

=item * info    -> list of all SSL/TLS info values (each can be used as command)

=item * pattern -> list of supported pttern for SSL/TLS cipher ranges (for +cipher)

=item * range   -> list of supported SSL/TLS cipher ranges (for +cipher)

=item * regex   -> list of most RegEx used internaly for SSL/TLS checks

=item * ourstr  -> list with RegEx matching special strings used in output

=item * tools   -> list of tools delivered with o-saft.pl

=item * hint    -> list texts used in !!Hint messages

=item * abbr

=item * glossar -> list of abbrevations and terms according SSL/TLS

=item * links   -> list of links according SSL/TLS (incomplete)

=item * rfc     -> list of RFCs according SSL/TLS (incomplete)

=item * faq     -> lists known problems and limitations

=item * todo    -> show list of TODOs

=item * error   -> show known problems about warning and error messages

=item * warnings -> show used message texts for warnings and errors

=item * intern  -> some internal documentations

=item * Program.Code  -> description of coding style, conventions, etc.

=back

=back

If any other string is used,  'printhelp()'  extracts just the section of
the documention which is headed by that string.

The  I<--header>  option can be used for simple formatting.

Note that above list is also documented in ./OSaft/Doc/help.txt in section
"Options for help and documentation".
In a perfect world it would be extracted from there (or vice versa).

=head1 VERSION

2.3 2022/06/15

=head1 AUTHOR

14-nov-14 Achim Hoffmann

=cut

## PACKAGE }

#_____________________________________________________________________________
#_____________________________________________________________________ self __|

_main_man(@ARGV) if (not defined caller);

1;

# SEE Note:Documentation (in o-saft.pl)

__END__

=pod

=head1 Annotations, Internal Notes

The annotations here are for internal documentation only.
For details about our annotations, please SEE  Annotations,  in o-saft.pl.


=head2 Perlcritic:LocalVars

Perl::Critic  complains that the variable $a should be localised in of the
code, this is wrong,  because it is exactly the purpose to find this value
(other settings) in other lines.
Hence  "no critic Variables::RequireLocalizedPunctuationVars"  needs to be
set in each line using $a.


=head2 Help:Syntax

The text for documentation is derivied from "help.txt" aka @help using:

    OSaft::Doc::Data::get_markup("help.txt")

This text contains some  simple (intermediate) markup,  which then will be
transformed to the final markup, such as HTML, POD, wiki.
Some sections in that text are handled special or needs to be completed.
These special sections are mainly identified by lines starting as follows:

    Commands for ...
    Commands to ...
    Discrete commands to test ...
    Options for ...
    Options to ...

These strings are hardcoded here. Take care when changing "help.txt".
See also "OSaft/Doc/Data.pm".

NOTE also that  o-saft.tcl  mainly uses the same texts for extra handling.


=head2 POD:Syntax

The special POD keywords  =pod  and  =cut  cannot be used as  literal text
in particular in here documents, because (all?) most tools  extracting POD
from this file (for example perldoc) would be confused.
Hence these keywords need to be printed in a separate statement.

=head3 POD:Dragons

POD's  =head2  cannot contain  ()  literally,  it needs at least one space
between  (  and  ) , otherwise formatting will be wrong.

POD's  CE<lt>$somethingE<gt>  Does not print  "$something"  but simply  $something
unless  $somthing  contains  =  or  *  character, i.e.  $some=thing. Hence
we use  IE<lt>$somethingE<gt>  instead.

POD does not support nested formatting, at least no prober syntax could be
found.


=head2 HTML:HTML

The complete documentation can be returned as HTML page. The generation is
straight forward, see  function man_html().  Some details of the generated
page are described in: SEE HTML:p  and  SEE HTML:JavaScript.

In general, following rules must apply to the  input data used to generate
HTML:

  * strings for commands and options start with '+' or '-'
  * if options have a value, the syntax must be: --option=VALUE, where the
    VALUE must be written upper-case
  * commands and options may be grouped by level 3 head lines

Data (text) in this format is returned by  OSaft::Doc::Data::get_markup().

NOTE most functions use following global variables:

  * @help
  * $parent
  * $mytool


=head2 HTML:CGI

The HTML page with the form for the CGI should look as follows:

 +-----------------------------------------------------------------------+
 | O - S a f t   — ...                                                   T
 +-----------------------------------------------------------------------+
 | Help: [help] [commands] [checks] [options] [FAQ] [Glossar] [ToDo]     H
 |+--------------------------------------------------------------------+ H
 || Hostname: [_________________________________] [+check]             c |
 ||                                                                    c |
 ||   [+check]  Check SSL connection ...                               c |
 ||   [+cipher] Overview of SSL connection ...                         c |
 ||   ...                                                              c |
 ||                                                                    c |
 || [Commands & Options]                                               O |
 ||+-----------------------------------------------------------------+ | |
 ||| ( ) --header     ( ) --enabled     ( ) --options     [Full GUI] q | |
 ||| ...                                                             q | |
 ||| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - | | |
 ||| COMMANDS                                           [Simple GUI] o | |
 ||| ( ) +cmd                                                        o | |
 ||| ...                                                             o | |
 ||| OPTIONS                                                         o | |
 ||| ( ) --opt                                                       o | |
 ||| (   --opt=[________]                                            o | |
 ||| ...                                                             o | |
 ||| [^] [start]                                                     o | |
 ||+-----------------------------------------------------------------+ | |
 |+--------------------------------------------------------------------+ |
 +-----------------------------------------------------------------------+

All commands and options avaialable in o-saft.pl are provided in the form.
Additional to the hostname or URL,  all selected commands and options will
be passed as QUERY_STRING to o-saft.cgi (which is the form's action), when
[start]  button is clicked.

The Interfase (web page) consist of following sections:

  T    title
  H    line with buttons opening a new TAB with corresponding help text
  c    input field for the hostname (target) and buttons for the most used
       commands
  O    Options button opens the section with the most often used options
  q    list with the most often used options, and the button [Full GUI] to
       show all available commands and options
  o    all available commands and options,  and the button [Simple GUI] to
       switch back to the simple list of options


=head2 HTML:INPUT

Options are  --opt  or  --opt=VALUE .  A simple checkbox is sufficient for
options without a value:

    <input type=checkbox name='--opt' value='' >--opt

Options with a value need an input field for the value, and a reset button
to undo changes. Additionally, the key=value should only be send on submit
of the form if the value was changed.  The change will be checked with the
form's onsubmit event (which calls osaft_submit(); for details see there). 
The generated HTML looks like:

   <label onclick=osaft_set_default(id) >
   <input type=text id='--opt=VALUE' name='--opt' value=VALUE osaft=VALUE>

The input field's name is the option itself, and the value is the option's
value. 

NOTE:  there may be the options  --opt  and  --opt=val  that's why input's
id attribute is set to  --opt=val instead of just  --opt ; all ids must be
unique!


=head2 HTML:p

For HTML format a paragraph tag '<p>' is used for all text blocks enclosed
in empty lines.  As RegEx are used to substitute the  markup text to HTML,
empty paragraphs may be generated. This is harmless,  as browsers will not
render empty paragraphs.

Old-style '<p>' is used even we know that '<div>' is the modern standard.
This simplifies formating with CSS.


=head2 HTML:JavaScript

When generating the HTML page (wether plain HTML or CGI), each description
text for commands and options is placed in a paragraph ('<p>' tag),  which
has an 'id' attribute set to the name of the command or option.  This name
is prefixed with the letter 'h'. Example: the description of the '+cipher'
command is placed in a paragraph like: <p id='h+cipher'> ... </p>.
These paragraphs are generated in  '_man_html()'.

This allows to extract the desciption text after generating the page using
JavaScript. See JavaScript function  'osaft_buttons()'.


=head2 HTML:start

The documenation in HTML format contains a "start" button at the bottom of
each toplevel section.  This should only be done when the page is used for
CGI (aka --help=cgi).


=head2 HTML:Known Bugs

Our options and commands (like +cipher --help) are not detected in lists.

=cut
