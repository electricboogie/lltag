package Lltag::Tags ;

use strict ;
no strict "refs" ;

use vars qw(@EXPORT) ;

@EXPORT = qw (
	      append_tag_value
	      get_tag_value_array
	      get_tag_unique_value
	      get_values_non_regular_keys
	      get_values_non_regular_keys
	      get_additional_tag_values
	      edit_values
	      ) ;

# add a value to a field, creating an array if required
sub append_tag_value {
    my $self = shift ;
    my $values = shift ;
    my $field = shift ;
    my $value = shift ;
    if (not defined $values->{$field}) {
	$values->{$field} = $value ;
    } elsif (ref($values->{$field}) ne 'ARRAY') {
	@{$values->{$field}} = ($values->{$field}, $value) ;
    } else {
	push @{$values->{$field}}, $value ;
    }
}

# append a set of unique values into and old hashes, depending of clear/append options
sub append_tag_values {
    my $self = shift ;
    my $old_values = shift ;
    my $new_values = shift ;

    if ($self->{clear_opt}) {
	$old_values = () ;
    }

    foreach my $field (keys %{$new_values}) {
	$old_values->{$field} = undef
	    if defined $old_values->{$field} and !$self->{append_opt} ;
	append_tag_value $self, $old_values, $field, $new_values->{$field} ;
    }

    return $old_values ;
}


# return values for a field as an array
sub get_tag_value_array {
    my $self = shift ;
    my $values = shift ;
    my $field = shift ;
    if (not defined $values->{$field}) {
	return () ;
    } elsif (ref ($values->{$field}) eq 'ARRAY') {
	return @{$values->{$field}} ;
    } else {
	return ($values->{$field}) ;
    }
}

# return a unique value for a field
sub get_tag_unique_value {
    my $self = shift ;
    my $values = shift ;
    my $field = shift ;
    my @array = get_tag_value_array $self, $values, $field ;
    die "Trying to return a unique tag value on an empty array.\n"
	if ! @array ;
    return $array[0] ;
}

# return non-regular keys whose value is defined
sub get_values_non_regular_keys {
    my $self = shift ;
    my $values = shift ;
    return grep {
	my $key = $_ ;
	!(grep { $_ eq $key } @{$self->{field_names}})
    } (keys %{$values}) ;
}

# handle additional tags
sub get_additional_tag_values {
    my $self = shift ;
    foreach my $string (@{$self->{additional_tags}}) {
	if ($string =~ /^([^=]+)=(.*)$/) {
	    append_tag_value $self, $self->{additional_values}, $1, $2 ;
	} else {
	    die "Additional tags must be given as 'TAG=value'.\n" ;
	}
    }
}

#######################################################
# edit current tags

sub edit_values {
    my $self = shift ;
    my $values = shift ;

    my $field_names_ref = shift ;
    my @field_names = @{$field_names_ref} ;

    my @letters = map { $self->{field_name_letter}{$_} } @field_names ;
    my $letters_union = join '|', @letters ;

    # save values
    my $old_values = () ;
    map { $old_values->{$_} = $values->{$_} } (keys %{$values}) ;

    while (1) {
	Lltag::Misc::print_question ("    Edit a field [". (join '', @letters) ."ECV,<h>elp] ? ") ;
	my $edit_reply = <> ;
	chomp $edit_reply ;

	if ($edit_reply =~ /^($letters_union)$/) {
	    my $field = $self->{field_letter_name}{$edit_reply} ;
	    $values->{$field} = Lltag::Misc::readline ("      ", ucfirst($field)." field", $values->{$field}, 1) ;

	} elsif ($edit_reply eq "E") {
	    return $values ;

	} elsif ($edit_reply eq "C") {
	    return $old_values ;

	} elsif ($edit_reply eq "V") {
	    print "      Current tag values are:\n" ;
	    foreach my $field (@field_names) {
		print "        ".ucfirst($field).$self->{field_name_trailing_spaces}{$field}.": "
		    . ($values->{$field} eq "" ? "<CLEAR>" : $values->{$field}) ."\n"
		    if defined $values->{$field} ;
	    }

	} else {
	    # print all fields, including the undefined ones
	    foreach my $field (@field_names) {
		my $val = $values->{$field} ;
		if (not defined $val) {
		    $val = "<not defined>" ;
		} elsif ($val eq "") {
		    $val = "<CLEAR>" ;
		}
		print "      ".$self->{field_name_letter}{$field}
		." => Edit ".ucfirst($field).$self->{field_name_trailing_spaces}{$field}
		." (".$val.")\n" ;
	    }
	    # TODO: show other fields ? not possible until we edit existing tags
	    print "      V => View current fields\n" ;
	    print "      E => End edition\n" ;
	    print "      C => Cancel edition\n" ;
	}
    }
}

1 ;
