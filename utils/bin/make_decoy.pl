#!/usr/bin/perl -W
###########################################################################
#
#    Author: Tom Price, University of Pennyslvania
#      Date: 10/18/2007
#
#    Copyright (C) 2007
#
###########################################################################


###########################################################################


sub getDb
{ 
   sub getaccession
   {
      $_ = shift ( @_ );
      /IPI:([^|. ]+)/
         and return $1;
      /(gi\|\d+)/
         and return $1;
      return $_;
   }

   my ( $db ) = @_;
   die "Error: cannot find $db\n" 
      if ( ! -e $db );
   open( DB, $db ) 
      or die "Error: cannot open $db $!\n"; 

   my %proteins;
   my $prot;
   my $protein;
   my $annot;
   my $count = 0;
   my $isseq = 0;
   my $previous;
   my $seq;
                    
   %proteins = ();
   
   $_ = <DB>;
   do
   {
      ##if ( /^\>(?:\S+?:)?(\S+?)(?:\.\d+)?(?:\|\S+)?\s+(\S.*\S)/ ) 
      if ( $_ && /^\>(\S+)\s+(\S.*\S)/ )
      {
      	$prot = getaccession( $1 );
         ##print "$prot\n";
         ##$annot = $2;
         $seq = '';               
      	
      	# get rid of illegal xml symbols
      	##$annot =~ s/\"/\'/g; # cover quotes
      	##$annot =~ s/\&/and/g; # cover &
      	##$annot =~ s/\>/\)/g;
      	##$annot =~ s/\</\(/g;

         # get sequence, assuming fasta format in DB  
         do 
         {
            $_ = <DB>;
            $isseq = ( defined && ! /^\>/ );
            if ( $isseq )
            {           
               chomp;
               $seq .= $_;
            }
         }
         while ( $isseq );
         $previous = $_;
         $count++;
         $proteins{ $prot } = $seq;
      }
      ##elsif ( /^\>(?:\S+?:)?(\S+?)(?:\.\d+)?(?:\|\S+)?/ ) 
      elsif ( $_ && /^\>(\S+)/ )
      {
         $prot = getaccession( $1 );
         $seq = '';
         # get sequence, assuming fasta format in DB 
         do 
         {
            $_ = <DB>;
            $isseq = ( defined && ! /^\>/ );
            if ( $isseq )
            {
               chomp;
               $seq .= $_;
            }
         }
         while ( $isseq );
         $previous = $_;
         $proteins{ $prot } = $seq;
      }
      $_ = ( $isseq ) ? <DB> : $previous;
   }
   while ( defined( $previous ) );
   close( DB );
   return \%proteins;
}

###########################################################################

sub revDb 
{
   my ( $ref_db ) = @_;
   my %proteins = %{ $ref_db };
   my %new_proteins;
   foreach $prot ( keys %proteins )
   {
      $new_proteins{ "REV_" . $prot . "  (reversed $prot)" } = scalar reverse $proteins{ $prot };
   }
   return \%new_proteins;
}

###########################################################################

sub printDb 
{
   my ( $ref_db ) = @_;
   my %proteins = %{ $ref_db };
   foreach $prot ( sort keys %proteins )
   {
      print ">$prot\n";
      print $proteins{ $prot }, "\n";
   }
}

###########################################################################

# fwdrev.pl : turns FASTA sequence into forward-and-reverse sequence database 
#
# syntax:
# perl fwdrev.pl input_db > output_db

# save reversed FASTA database
#
my ( $input_db ) = @ARGV;
my %db    = %{ getDb( $input_db ) };
my %revDb = %{ revDb( \%db ) };

system("cat $input_db");

printDb( \%revDb );  
