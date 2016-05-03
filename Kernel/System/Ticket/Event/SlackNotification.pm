# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

package Kernel::System::Ticket::Event::SlackNotification;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request::Common;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::Ticket
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    $LogObject->Log(
        Priority => 'notice',
        Message  => 'Run SlackNotification event module',
    );

    # get ticket attribute matches
    my %Ticket = $TicketObject->TicketGet(
        TicketID => $Param{Data}->{TicketID},
        UserID   => 1,
    );

    my $WebhookURL   = $ConfigObject->Get( 'SlackNotification::WebhookURL' );
    my $BotName = $ConfigObject->Get( 'SlackNotification::BotName' );
    my $Icon   = $ConfigObject->Get( 'SlackNotification::Icon' );

    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(POST => $WebhookURL);
    $req->header('content-type' => 'application/json');

    # add POST data to HTTP request body
    my $post_data = "{
      \"username\": \"$BotName\",
      \"icon_emoji\": \"$Icon\",
      \"text\": \"New ticket <http://otrs.podium-market.com/otrs/index.pl?Action=AgentTicketZoom;TicketID=$Ticket{TicketID}|$Ticket{TicketID}>\",
    }";
    $req->content($post_data);

    my $resp = $ua->request($req);


    return 1;
}

1;
