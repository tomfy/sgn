package SGN::Controller::Contact;

use Moose;
use namespace::autoclean;
use CXGN::People;

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

SGN::Controller::Contact - controller for contact page

=cut

#reference holds the URL of the page user was last on
has 'reference' => (
    is       => "rw",
    isa      => 'Str',
    required => 0,
    default  => '',
);

#Creates a blank form
sub form :Path('/contact/form') :Args(0) {
    my ($self, $c) = @_;
    my ($username, $useremail) = _load_user($c);
    _build_form_page($self, $c, $username, $useremail);
}

#Loads the user if he has an account
sub _load_user {
    my ($c) = @_;
    my $dbh = $c->dbc->dbh;
    my $user = $c->user_exists ? $c->user->get_object : CXGN::People::Person->new( $dbh, undef );

    # TODO: we shouldn't have to dig into {user} here
    my ($username, $useremail) = ($user->id, $user->{user}->get_private_email());


    return ($username, $useremail);
}

#Builds a form with $name, $email, $subject, $body in the right line
#If any undef, assigns ''
sub _build_form_page {
    my ($self, $c, $name, $email, $subject, $body) = @_;
    $c->stash->{name}                     = $name if $name;
    $c->stash->{email}                    = $email if $email;
    $c->stash->{subject}                  = $subject if $subject;
    $c->stash->{body}                     = $body if $body;
    $c->stash->{email_address_to_display} = 'sgn-feedback@solgenomics.net';
    $c->stash->{template}                 = '/help/contact.mas';
}

sub submit :Path('/contact/submit') :Args(0)
{
    my ($self, $c) = @_;
    my ($name, $email, $subject, $body) =
        map { $c->request->param($_) } qw/name email subject body/;
    my $reference = $self->reference;
    if ($name and $email and $subject and $body) {
       $body = <<END_HEREDOC;
From:
$name <$email>

Subject:
$subject

Body:
$body

Referred from:
$reference

END_HEREDOC

       $c->stash->{email} = {
        to      => $c->config->{bugs_email},
        from    => 'sgn-feedback@solgenomics.net',
        subject => "[contact] $subject",
        body    => $body,
       };

       $c->forward('View::Email');

       $c->stash->{message} = "Thank you. Your message has been sent.";
       $c->stash->{template} = "/gen_pages/message.mas";
    } else {
       my %info_fields = (
            name    => $name,
            email   => $email,
            subject => $subject,
            body    => $body
        );
       foreach my $category (keys %info_fields)
       {
         $c->stash->{filled}->{$category} = $info_fields{$category};
       }
       _build_form_page($self, $c, $name, $email, $subject, $body);
    }
}

__PACKAGE__->meta->make_immutable;
1;
