UserTag row-edit HasEndTag
UserTag row-edit Order key table size columns
UserTag row-edit addAttr
UserTag row-edit Interpolate 1
UserTag row-edit Routine <<EOR
sub {
	my ($key,$table,$size,$columns,$opt) = @_;
	use vars qw/$CGI %Db $Values $Variable/;
#::logDebug("row_edit options=" . ::uneval($opt));
	$table = $table || $CGI::values{mv_data_table} || return "BLANK DB";
	my $db = $Db{$table} || Vend::Data::database_exists_ref($table);
	my $mtab = $Variable->{UI_META_TABLE} || 'mvmetadata';
	my $mdb = $Db{$mtab} || Vend::Data::database_exists_ref($mtab);
	$opt->{view} ||= $CGI->{ui_meta_view};

	my $view = UI::Primitive::meta_record($table, $opt->{view}) || {};
	
	return errmsg("non-existent table '%s' for row-edit", $table)
		unless $db;
	$db = $db->ref();

	my $acl = UI::Primitive::get_ui_table_acl();

	my $bad;
	if ($key) {
		eval {
			$bad = ! $db->record_exists($key);
			$bad = 'DELETED' if $bad;
		};
		$bad = 'ERROR' if $@;
		if(! $bad and $acl) {
			$bad = 'Not available'
				if ! UI::Primitive::ui_acl_atom($acl, 'keys', $key);
		}
	}

	my @cols;

	if($columns ||= $view->{spread_cols} || $view->{attribute}) {
		@cols = split /[\s,\0]+/, $columns;
		my %col;
		for(@cols) {
			$col{$_} = 1;
		}
		@cols = grep defined $col{$_}, $db->columns();
	}
	else {
		@cols = $db->columns();
	}

	if($acl) {
		@cols = UI::Primitive::ui_acl_grep( $acl, 'fields', @cols);
	}

	# See if we have a textarea reference
	my %ta;
	if($opt->{textarea}) {
		my @tmp = split /[\s,\0]+/, $opt->{textarea};
		for(@tmp) {
			$ta{$_} = 1;
		}
	}

	my $out = '';

	my $meta = $CGI->{ui_no_meta_display} ? '' : $view->{type};
	my $tmp;

	$size = $size || $view->{width} || 12;
	if($bad) {
		for(@cols) {
			$out .= "<TD>$bad</TD>";
		}
	}
	elsif($key) {
		my $text;
		for(@cols) {
			eval {
				$text = $db->field($key,$_);
			};
			$text = 'DELETED' if $@;
			my $msg = '';
			if($meta) {
				if	( $view->{type} =~ /combo|checkbox|multi|date|image|option_format/) {
					$msg = '<br><small><small>unable to display with field info</small></small>';
				}
				else {
					my $tmp = UI::Primitive::meta_display($table,$_,$key,$text);
					$out .= "<TD>$tmp</TD>";
					next;
				}
			}
			
			if($ta{$_} || $text =~ /\n/) {
				my $rows = $opt->{height} || 4;
				$text =~ s/</&lt;/g;
				$text =~ s/\[/&#91;/g;
				$out .= <<EOF;
<TD><TEXTAREA NAME="$_" COLS="$size" ROWS="$rows">$text</TEXTAREA>$msg</TD>
EOF
			}
			else {
				$text =~ s/"/&quot;/g;
				$out .= <<EOF;
<TD><INPUT NAME="$_" SIZE=$size VALUE="$text">$msg</TD>
EOF
			}
		}
	}
	elsif($opt->{blank}) {
		for(@cols) {
				$out .= <<EOF;
<TD><INPUT NAME="$_" SIZE=$size VALUE=""></TD>
EOF
		}
	}
	else {
		for(@cols) {
				$out .= <<EOF;
<TH ALIGN=left>$_</TH>
EOF
		}
	}
	return $out;

}
EOR

