import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Types "../ICRC72Types";

module {
    public class SubscriptionManager() = Self {
        private var subscriptions : HashMap.HashMap<Principal, [Types.SubscriptionInfo]> = HashMap.HashMap<Principal, [Types.SubscriptionInfo]>(10, Principal.equal, Principal.hash);
        let current_broadcaster = "rvrj4-pyaaa-aaaal-ajluq-cai"; //default broadcaster

        public func icrc72_register_single_subscription(current_broadcaster : Text, subscription : Types.SubscriptionInfo) : async (Bool, Text) {
            let broadcaster : Types.BroadcasterActor = actor (current_broadcaster);
            let result = await broadcaster.icrc72_register_subscription([subscription]);
            if (result[0].1) {

                subscriptions.put(subscription.subscriber, [subscription]);
            };
            return (result[0].1, subscription.namespace);
        };

        public func icrc72_register_subscription(subscriptionInfos : [Types.SubscriptionInfo]) : async [(Types.SubscriptionInfo, Bool)] {
            var results = Buffer.Buffer<(Types.SubscriptionInfo, Bool)>(subscriptions.size());
            for (subscription in subscriptionInfos.vals()) {
                subscriptions.put(subscription.subscriber, [subscription]);
                let result = await icrc72_register_single_subscription(current_broadcaster, subscription);
                results.add((subscription, result.0));
            };
            return Buffer.toArray(results);
        };

        public func getSubscribersByNamespace(namespace : Text) : async [Principal] {
            let result = Buffer.Buffer<Principal>(0);
            label a for (subscriber in subscriptions.keys()) {
                let subscriber_subscriptions = await getSubscriptionInfo(subscriber);
                for (subscription in subscriber_subscriptions.vals()) {
                    if (subscription.namespace == namespace) {
                        result.add(subscriber);
                        continue a;
                    };
                };
            };
            return Buffer.toArray(result);
        };

        public func getSubscriptionsByNamespace(namespace : Text) : async [Types.SubscriptionInfo] {
            let result = Buffer.Buffer<Types.SubscriptionInfo>(0);
            label b for (subscriber in subscriptions.keys()) {
                let subscriber_subscriptions = await getSubscriptionInfo(subscriber);
                for (subscription in subscriber_subscriptions.vals()) {
                    if (subscription.namespace == namespace) {
                        result.add(subscription);
                        continue b;
                    };
                };
            };
            return Buffer.toArray(result);
        };

        // Get subscription information for a specific subscriber
        public func getSubscriptionInfo(subscriber : Principal) : async [Types.SubscriptionInfo] {
            Option.get(subscriptions.get(subscriber), []);
        };

        // Get all subscriptions for all subscribers
        public func getSubscriptions() : async [Types.SubscriptionInfo] {
            let result = Buffer.Buffer<Types.SubscriptionInfo>(0);
            for (subscriber in subscriptions.keys()) {
                let subscriber_subscriptions = await getSubscriptionInfo(subscriber);
                for (subscription in subscriber_subscriptions.vals()) {
                    result.add(subscription);
                };
            };
            return Buffer.toArray(result);
        };

        // Unsubscribe a subscriber from a specific namespace
        public func unsubscribeByNamespace(subscriber : Principal, namespace : Text) : async () {
            let existingSubs = Option.get(subscriptions.get(subscriber), []);
            let filteredSubs = Array.filter<Types.SubscriptionInfo>(
                existingSubs,
                func(info : Types.SubscriptionInfo) : Bool {
                    info.namespace != namespace;
                },
            );
            if (filteredSubs.size() == 0) {
                ignore subscriptions.remove(subscriber);
            } else {
                subscriptions.put(subscriber, filteredSubs);
            };
        };

        // Unsubscribe a subscriber from all namespaces
        public func unsubscribeAll(subscriber : Principal) : async () {
            ignore subscriptions.remove(subscriber);
        };

        // Update the status of a subscription (e.g., pause or resume)
        public func updateSubscriptionStatus(subscriber : Principal, namespace : Text, active : Bool) : async () {
            let existingSubs = Option.get(subscriptions.get(subscriber), []);
            let updatedSubs = Array.map<Types.SubscriptionInfo, Types.SubscriptionInfo>(
                existingSubs,
                func(info : Types.SubscriptionInfo) {
                    if (info.namespace == namespace) {
                        {
                            namespace = info.namespace;
                            subscriber = info.subscriber;
                            active = active;
                            filters = info.filters;
                            messagesReceived = info.messagesReceived;
                            messagesRequested = info.messagesRequested;
                            messagesConfirmed = info.messagesConfirmed;
                        };
                    } else {
                        info;
                    };
                },
            );
            subscriptions.put(subscriber, updatedSubs);
        };
    };
};
