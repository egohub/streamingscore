use HTTP::Request::Common;
use HTTP::Cookies;
use LWP::UserAgent;
use Time::Local;


my $count=0;
my $access_token = 'AAA';
my $hStreamingScore, $hHistoryScore, $hCommentData, $hZeroData, $hInitData;
my $timeStamp;
my @realTimeScore=();
my $counter;
my $cookie_jar = HTTP::Cookies->new(autosave => 1);
my $browserGet = LWP::UserAgent->new(
 agent => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)'
);
my $browserPost = LWP::UserAgent->new(
 agent => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)'
);
#$browserGet->proxy('http', "BBB");
#open(IN, "testtest.html")   or die "Can't open input.txt: $!";

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$timeStamp=$year+1900;

#1. load persis message from file.
open(INFILE,  "persis.log") ;
while (<INFILE>) {
	my @tempString = split /\t/, $_;
	$tempString[1] =~ s/\n//g;
	push ( @{$hInitData{"$tempString[0]"}}, $tempString[1]."\t".$tempString[2]);
}
close INFILE;

#2. while true for get data all the time
while (true){	
	$count++;
	#3. extract data from livescore.com
	extractData();
	
	#4. compare data from update with persis data
	my $isPost = comPare();
	
	#5 if return true it will post to FP
	postFB($isPost);
	
	#6 sleep for new
	sleep 15;
}


#########################################################################################################
#
#	Function
#
#########################################################################################################

sub get_timestamp {
   ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
   if ($mon < 10) { $mon = "0$mon"; }
   if ($hour < 10) { $hour = "0$hour"; }
   if ($min < 10) { $min = "0$min"; }
   if ($sec < 10) { $sec = "0$sec"; }
   $year=$year+1900;
   use Time::HiRes qw(gettimeofday);
   @_us     = gettimeofday;
   $ms     = substr(sprintf("%.3f", "0." . $_us[1]), 2);
   return "$year$mon$mday";
}

sub extractData {	
	#$filename = "debug.log"; open FH, ">".$filename or die "could notopen $filename: $!\n";
	%hStreamingScore = ();
	my $get = $browserGet->get('http://livescore.com');
	if ($get->is_success) {
		my $temp = $get->content;
		$temp =~ s/\n//g;
		#get body
		@body = ($temp =~ /<table width="468" bgcolor="#666666" cellspacing="0" cellpadding="0" border="0"><tr bgcolor="#111111"><td colspan="4" height="4">(.*?)<\/table>/);
		#get league
		@League = split /(?:<td colspan="4" height="4">)/, $body[0];
		for ($i=0; $i < @League; $i+=1) {		
			#get heading of each league return league name and time of match
			if (@heading = ($League[$i] =~ /<tr bgcolor="#333333">(.*?)<tr><td colspan="4" height="1">/)){
				@headingDetail = ($heading[0] =~ /<b>(.*?)<\/b>\s\-\s(.*?)<\/td>.*?\&nbsp\;(.*?)<\/td>.*?"3">(.*?)\&nbsp\;/);
				#print FH $headingDetail[0]." - ".$headingDetail[1]."\n";
				#print "Current time is ".$headingDetail[2]." on ".$headingDetail[3]."\n";
				#print FH "================================================================================================\n";

				my $teamHome;
				my $teamAway;
				my $homeScore;
				my $awayScore;
				my $timeInGame;
				my $actionMinute;
				my $actionInGame;
				my $actionBy;
				my $stringTemp;
				#get matchUp
				#return teamVs score score link time in match
				if (@matchUp = ($League[$i] =~ /<td width="45" height="18">(.*?)<\/td><\/tr>/g) ){
					for ($j=0; $j < @matchUp; $j+=1) {
						my $linkScore;
						$stringTemp="";
						$counter++;
						$teamHome="";
						$teamAway="";
						$homeScore="";
						$awayScore="";
						$timeInGame="";
						#get score detail
						#if($j == 0){print FH $matchUp[$j]; }
						@score = ($matchUp[$j] =~ /\&nbsp\;(.*?)<\/td><td align="right" width="186">(.*?)<\/td>(<[^>]+>){1,2}(.*?)<[^"]+"186">(.*)/);
						$teamHome=$score[1];
						$teamAway=$score[4];
						@tmp = split /(?:\-)/, $score[3];
						$homeScore=$tmp[0];
						$awayScore=$tmp[1];
						$score[0] =~ s/<img src="http:\/\/cdn3.livescore.com\/img\/flash.gif" width="8" height="8" border="0">//;
						$score[0] =~ s/\s//;
						$timeInGame=$score[0];
						#print $score[0]."\t".$score[1]."\t".$score[3]." vs. ".$score[4]."\n";
						#print FH "\t".$timeInGame."\t".$homeScore." - ".$awayScore."\t".$teamHome." vs. ".$teamAway."\n";
						if (@scoreLink = ($matchUp[$j] =~ /a class="scorelink".*?href="(.*?)"/)){
						#get score detail here.
							#print FH "http://livescore.com".$scoreLink[0]."\n";
							#print FH "Link detail|http://livescore.com".$scoreLink[0]."\n";
							$linkScore = "http://livescore.com".$scoreLink[0];
							#if ($j == 0 && $i==0){
							#$url = "http://livescore.com".$scoreLink[0];
							#$get = $browserGet->get($url);
							#$temp = $get->content;
							#$temp =~ s/\n//g;
							#print FH "$temp";
							@scoreDetail = ($temp  =~ /<tr class="(dark|light)"><td width="20">(.*?)border="0"/g);
							for ($k=1; $k < @scoreDetail; $k+=2) {
								#print FH "\nscore detail= $scoreDetail[$k]\n";
									if (@player = ($scoreDetail[$k] =~ /^(.*?)<\/td><td width="50".*?<b>(.*?)<\/b><\/td><td width="163"([^>]+>){1,3}(.*?)<img src="(.*?)"/)){
										@reason = ($player[4]  =~ /((?i)red|yellow|goal)/);
										#print FH "$player[0]\t$player[1]\t$player[3]\t has $reason[0]\n";
									}
							}
										   #}
						}
								   #print FH "------------------------------------------------------------------------------------------------\n";
						push ( @{$hStreamingScore{"$headingDetail[3]"."|"."$teamHome"."|"."$teamAway"}}, $timeInGame."\|".$homeScore."\|".$awayScore."\|".$teamHome."\|".$teamAway."\|".$linkScore."\|".$headingDetail[3]);
					}
				}
			}
		}
		#close FH;
	} else {
		print "##################Can't get response##################\n";
	}
}# end sub extractData


sub comPare {
	@realTimeScore=();
	my $isUpdate = "FALSE";
	foreach my $key1 (keys %hStreamingScore) {
		#foreach my $key2 (keys %hStreamingScore) {
		#print $key1."\n";
		my @oldScore = split /\t/, @{$hInitData{"$key1"}}[0];
		my @newScore = split /\|/, @{$hStreamingScore{"$key1"}}[0];
		my $time = $newScore[0];
		my @scoreOnInit = split /\s-\s/, $oldScore[1];		
		$scoreOnInit[0] =~ s/\[//;
		$scoreOnInit[1] =~ s/\]//;
		my $stringOld = "$scoreOnInit[0]$scoreOnInit[1]";
		my $stringNew = "$newScore[1]$newScore[2]";
		$stringOld =~ s/\s//g;
		$stringNew =~ s/\s//g;
		$newScore[1] =~ s/\?/0/g;
		$newScore[2] =~ s/\?/0/g;
		$newScore[1] =~ s/\s//g;
		$newScore[2] =~ s/\s//g;
		my $update = "$newScore[1]$newScore[2]";
		my $sumOld = $scoreOnInit[0] + $scoreOnInit[1];
		my $sumNew = $newScore[1] + $newScore[2];
		$update =~ s/\s//g;
		$time =~ s/\s//g;
		#print $pervious ." vs ".$update."\n"; Postp.
		#print $scoreOnInit[0].$scoreOnInit[1] ." vs ". $newScore[1].$newScore[2]."\n";;
		if ($stringOld eq ""){$sumOld = -1;}
		if (("$update" ne "") && ($sumNew > $sumOld) && ("$stringNew" ne "??") && ($time ne "Postp.") && ($time ne "AET") && ($time ne "Pen.") && ($time ne "Susp.") && ($time ne "FT") && ($time ne "HT")){
			$isUpdate = "TRUE";
			#print "$newScore[1] + $newScore[2]=$sumNew...$scoreOnInit[0] + $scoreOnInit[1]=$sumOld\n";
			#record the change score in game to $realTimeScore.
			#print $oldScore[1].$oldScore[2]."\n";
			#print @{$hStreamingScore{"$key1"}}[0]."\n";
			#print $pervious ." vs ".$update."\n";
			push (@realTimeScore, $newScore[0]."\t".$newScore[3]."\t\[".$newScore[1]." - ".$newScore[2]."\]\t".$newScore[4]."\t".$newScore[5]."\t".$newScore[6]);
		# } elsif (("$update" eq "00") && ("$stringNew" ne "??") && ($time ne "FT") && ($time ne "HT")){
			# if ( @{$hZeroData{"$newScore[3]"."|"."$newScore[4]"}}[0] ne "1"){
				# $isUpdate = "TRUE";
				# push (@{$hZeroData{"$newScore[3]"."|"."$newScore[4]"}}, "1");
				# push (@realTimeScore, $newScore[0]."\t".$newScore[3]."\t\[".$newScore[1]." - ".$newScore[2]."\]\t".$newScore[4]."\t".$newScore[5]);
			# }								  
		}
	}	
	print "$count\tisUpdate??\t$isUpdate\n";
	return $isUpdate;
}# end sub comPare


sub postFB {
	my ($isUpdate) = @_;
	
	if ($isUpdate eq "TRUE"){	
		#1. load persis message from file.
		%hCommentData = ();
		open(INFILE,  "persis.log") ;
		while (<INFILE>) {
			my @tempString = split /\t/, $_;
			$tempString[1] =~ s/\n//g;
			push ( @{$hCommentData{"$tempString[0]"}}, $tempString[1]."\t".$tempString[2]);
		}
		close INFILE;

		#2. update to FB page here!!!
		foreach my $newLine (@realTimeScore){
			my @stringKey = split /\t/, $newLine;
			my @dataOnHash = split /\t/, @{$hCommentData{"$stringKey[5]"."|"."$stringKey[1]"."|"."$stringKey[3]"}}[0];
			my @scoreOnHash = split /\s-\s/, $dataOnHash[1];
			my @scoreOnNewUpdate = split /\s-\s/, $stringKey[2];
			$scoreOnHash[0] =~ s/\[//;
			$scoreOnHash[1] =~ s/\]//;
			$scoreOnNewUpdate[0] =~ s/\[//;
			$scoreOnNewUpdate[1] =~ s/\]//;									   
			my $sumOnHash = $scoreOnHash[0] + $scoreOnHash[1];
			my $sumOnNewUpdate = $scoreOnNewUpdate[0] + $scoreOnNewUpdate[1] ;
			if ($scoreOnHash[0] eq "" | $scoreOnHash[1] eq ""){$sumOnHash=-1;}
			if ($sumOnNewUpdate > $sumOnHash){
				#print "$newLine\n";
				if ($dataOnHash[0]){
					print "Update data Block for $stringKey[1] vs $stringKey[3] on ".$dataOnHash[0]." from \[$scoreOnHash[0]-$scoreOnHash[1]\] to \[$scoreOnNewUpdate[0]-$scoreOnNewUpdate[1]\]\n";
					$get = $browserPost->post('https://graph.facebook.com/'.$dataOnHash[0].'/comments',
						[
							access_token => $access_token,
							message      => $stringKey[0]."\t".$stringKey[1]."\t".$stringKey[2]."\t".$stringKey[3]."\n".$stringKey[4],
							link         => 'http://www.facebook.com/pages/StreamingScore/278883242154232?sk=wall',
							picture      => 'http://football-sports.yolasite.com/resources/Football%20(1).jpg',
							name         => 'RealTime StreaminScore for Soccer',
							caption      => 'StreamingScore Fan Page',
							description  => 'This score has been retrieve data from http://livescore.com '
											. 'Please see more detail on the web page ',
							method       => 'post'
						]);

					   delete $hCommentData{"$stringKey[5]"."|"."$stringKey[1]"."|"."$stringKey[3]"};
					   push ( @{$hCommentData{"$stringKey[5]"."|"."$stringKey[1]"."|"."$stringKey[3]"}},$dataOnHash[0]."\t".$stringKey[2]);
			   }else{
					$get = $browserPost->post('https://graph.facebook.com/278883242154232/feed',
					   [
							access_token => $access_token,
							message      => $stringKey[0]."\t".$stringKey[1]."\t".$stringKey[2]."\t".$stringKey[3]."\n".$stringKey[4],
							name         => 'Post to your own Facebook account from a script',
							description  => 'This score has been retrieve data from http://livescore.com '
											. 'Please see more detail on the web page ',
							method       => 'post'
						]);

					$dataBlock = $get->content;
					$dataBlock =~ s/\n//g;
					@commentID = ($dataBlock =~ /"id":\s"(.*?)"/);
					if ($commentID[0] ne ""){
						print "Create New data Block for $stringKey[1] vs $stringKey[3] on ".$commentID[0]." with score $stringKey[2]\n";
						push ( @{$hCommentData{"$stringKey[5]"."|"."$stringKey[1]"."|"."$stringKey[3]"}}, $commentID[0]."\t".$stringKey[2]);
					}
				}				
			}	
		}

		#3. persis message to file.		
		$filename = "persis.log"; open INFILE, ">".$filename or die "could not open $filename: $!\n";
		
		# FOREACH LOOP
		foreach my $key1 (sort keys %hCommentData) {
			my $stringTemp = @{$hCommentData{"$key1"}}[0];
			$stringTemp =~ s/\n//g;
			if ($stringTemp ne ""){
				print INFILE "$key1\t$stringTemp\n";
			}
		}
		close INFILE;		
		%hInitData = %hCommentData;
	}
}# end sub postFB
