package Bric::App::Callback::SelectTime;

# XXX: I think this needs looked at closer because there
# are some conventions on passing "subwidget" data
# that might not make the transition to MasonX::...

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'select_time');
use strict;
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:all);


my $defs = {
    min  => '00',
    hour => '00',
    day  => '01',
};


sub refresh : Callback(priority => 0) {
    my $self = shift;
    my $param = self->param;
    return if $is_clear_state->($param);

    # There might be many time widgets on this page.
    my $base = mk_aref($self->param_field);

    foreach my $b (@$base) {
        # Keep this widget with this base name distict from others on the page.
        my $sub_widget = CLASS_KEY . ".$b";
        my @vals;
        my $incomplete = 0;
        # This is compliments $incomplete.  It tells whether *any* time fields
        # were set.  This way we know if they started to add time fields, but
        # then stopped.
        my $has_data = 0;

        foreach my $unit (qw(year mon day hour min)) {
            my $f = $b . '_' . $unit;
            my $v = $param->{$f};

            # Set the incomplete flag and stop if we get an unset date value.
            if ($v eq '-1') {
                $defs->{$unit} ? (push @vals, $defs->{$unit}) : ($incomplete = 1);
            } else {
                $has_data = 1;

                # Collect the values.
                push @vals, ($v || '0');
            }

            # Update all the time values.
            set_state_data($sub_widget, $unit, $v) if defined $v;
        }

        if ($incomplete) {
            # If some fields were set, flag it
            if ($has_data) {
                $param->{$b . '-partial'} = 1;
            } else {
                # It's undefined.
                $param->{$b} = undef;
            }
        } else {
            my $date = sprintf("%04d-%02d-%02d %02d:%02d:00", @vals);
            # Write the date to the parameters.
            $param->{$b} = $date;
        }
    }
}

sub clear : Callback {
    my $self = shift;

    # If the trigger field was submitted with a true value then, clear state!
    if ($is_clear_state->($self->param)) {
        my $s = \%HTML::Mason::Commands::session;

        # Find all the select_time widget information
        my @sel = grep(substr($_,0,11) eq 'select_time', keys %$s);

        # Clear out all the state data.
        foreach my $sub_widget (@sel) {
            set_state_data($sub_widget, {});
        }
    }
}

###

my $is_clear_state = sub {
    my ($param) = @_;
    my $trigger = $param->{CLASS_KEY . '|clear_cb'} || return;
    return $param->{$trigger};
};


1;
