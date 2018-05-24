#!/usr/bin/perl -w
# $Header: XXCUSEXE.pl 115.0 2008/12/30 00:00:00 fbarros noship $
# *===========================================================================+
# |  Copyright (c) 2003 Oracle Corporation, Redwood Shores, California, USA   |
# |                        All rights reserved                                |
# |                       Applications  Division                              |
# +===========================================================================+
# |
# | FILENAME
# |   XXCUSEXE.pl
# |
# | DESCRIPTION
# |   XX Ejecutar Customizaciones
# |
# | USAGE
# |
# | NOTES
# |
# | HISTORY
# |
# +===========================================================================+
use strict;
	
print_header("Iniciando ejecutar customizaciones");


my $cmd_line = "";
	
# if not FULL mode, exit successfully without doing anything
if (! $ARGV[0] ) {
    exit(0);
} else {
    $cmd_line = $ARGV[0];
}	

# -- Get the request context object
my $context = get_context();

my $log = $context->log();
$log->timestamp("apps user " .  $context->apps_user());
$log->timestamp("apps pwd  " .  $context->apps_pwd());


print_header("Ejecutando el comando"); 
print "cmd_line: ", $cmd_line, "\n";
eval { 
   system ( $cmd_line ); 
}; 

if ($@) {
   print_header("Finalizando con error" . $@);
   exit(1);

}

# -- Exiting the script 
# -- The exit status of the script will be used as the concurrent program exit status.
# -- A non-zero exit status will be reported as an error.
print_header("Finalizando normal");
exit(0);

sub print_header {

  my $msg = shift;
  print "\n\n", "-" x 40, "\n", $msg, "\n", "-" x 40, "\n";

}
