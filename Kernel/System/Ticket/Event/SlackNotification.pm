# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

package Kernel::System::Ticket::Event::SlackNotification;

use strict;
use warnings;

use LWP::UserAgent;

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

    # check needed stuff
    for my $NeededParam (qw(Event Data Config UserID)) {
        if ( !$Param{$NeededParam} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $NeededParam!",
            );
            return;
        }
    }

    for my $NeededData (qw(TicketID ArticleID)) {
        if ( !$Param{Data}->{$NeededData} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $NeededData in Data!",
            );
            return;
        }
    }

    # get ticket attribute matches
    my %Ticket = $TicketObject->TicketGet(
        TicketID => $Param{Data}->{TicketID},
        UserID   => 1,
    );
    my %Article = $TicketObject->ArticleFirstArticle(
        TicketID => $Param{Data}->{TicketID},
    );

    $LogObject->Log(
        Priority => 'notice',
        Message => 'Sender-/ArticleType: ' . join '::', @Article{qw(SenderType ArticleType)},
    );

    return 1 if $Article{ArticleID} != $Param{Data}->{ArticleID};
    return 1 if $Article{SenderType} ne 'customer' || $Article{ArticleType} ne 'email-external';


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
      \"text\": \"New ticket <http://otrs.podium-market.com/otrs/index.pl?Action=AgentTicketZoom;TicketID=$Ticket{TicketID}|$Ticket{TicketID}> $Article{Subject}\", 
    }";
    $req->content($post_data);

    my $resp = $ua->request($req);
    if ($resp->is_success) {
        my $message = $resp->decoded_content;
        print "Received reply: $message\n";
    }
    else {
        print "HTTP POST error code: ", $resp->code, "\n";
        print "HTTP POST error message: ", $resp->message, "\n";
    }


    return 1;
}

1;
