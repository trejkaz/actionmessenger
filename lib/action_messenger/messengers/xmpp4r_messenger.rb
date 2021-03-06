module ActionMessenger
  module Messengers
    class Xmpp4rMessenger < ActionMessenger::Messenger
      # Creates a new messenger from its config hash.
      #
      # Hash can contain:
      #    jid:      the Jabber ID of this messenger, with resource if you wish.
      #    password: the password for this messenger.
      #    host:     hostname of the server if different from the server specified in the SRV records for the Jabber ID.
      #    port:     port of the server if not the default specified in the SRV records (or if SRV records are absent, 5222).
      def initialize(config_hash = {})
        super(config_hash)
        @listeners = []
      
        # Sanity check the JID to ensure it has a resource, and add one ourselves if it doesn't.
        jid = config_hash['jid']
        jid += '/ActionMessenger' unless jid =~ /\//
      
        # TODO: Different strategies for staying online (come online only to send messages.)
        # TODO: Reconnection strategy.
        # TODO: Multiple mechanisms for sending messages, for Jabber backend swap-out,
        #       but also to unit test the sending code.
        @client = Jabber::Client.new(Jabber::JID.new(jid))
      
        # Pass custom host and/or port to connect.
        args = [ config_hash['host'] ]
        args << config_hash['port'] if config_hash['port']
      
        @client.connect(*args)
        @client.auth(config_hash['password'])
        
        @client.add_message_callback do |jabber_message|
          message = ActionMessenger::Message.new
          message.to = jabber_message.to.to_s
          message.from = jabber_message.from.to_s
          message.body = jabber_message.body
          message.subject = jabber_message.subject
          message_received(message)
        end
      end
    
      # Sends a message.
      def send_message(message)
        to = message.to
        to = Jabber::JID.new(to) unless to.is_a?(Jabber::JID)
        jabber_message = Jabber::Message.new(to, message.body)
        jabber_message.subject = message.subject
        @client.send(jabber_message)
      end
      
      # TODO: See if there is a way to have this called on exit, for a more friendly shutdown.
      def shutdown
        unless @client.nil?
          @client.close
          @client = nil
        end
      end
    end
  end
end
