<script>
	// @ts-nocheck

	import { onMount } from "svelte";
	import { writable, get } from "svelte/store";
	import {
		isLoading,
		handleNotifications,
		nextNotification,
	} from "$lib/notification-store";
	import Notification from "./components/Notification.svelte";
	import CustomTypography from "./components/CustomTypography.svelte";
	import {
		isAuthenticated,
		principalId,
		client_canister_actor,
		client_canister,
		CANISTER_ID_EVENT_XPERIENCE_BACKEND,
	} from "./auth.js";
	import { Principal } from "@dfinity/principal";

	let principal = "";
	let messagesMapStore = writable(new Map());
	let loggedIn = false;

	principalId.subscribe((value) => {
		principal = value;
	});

	isAuthenticated.subscribe((value) => {
		loggedIn = value;
	});

	const TARGET_PRINCIPAL = CANISTER_ID_EVENT_XPERIENCE_BACKEND;

	function getNextId() {
		let next = get(nextNotification) + 1;
		nextNotification.set(next);
		return BigInt(next);
	}

	onMount(() => {
		// console.log('onMount start');
		handleNotificationsImpl();
	});

	async function handleNotificationsImpl() {
		isLoading.set(true);
		let actor = client_canister_actor;
		try {
			if (!client_canister_actor) {
				actor = await client_canister();
			}
			console.log("Getting notifications for user: ", TARGET_PRINCIPAL);
			let result = await actor.getNotificationsByUser(TARGET_PRINCIPAL);
			// console.log('Notifications: ', result);
			if (Array.isArray(result[1])) {
				messagesMapStore.update((map) => {
					return new Map(map.set(TARGET_PRINCIPAL, result[1]));
				});
			} else {
				console.error("Unexpected result format:", result);
			}
		} catch (error) {
			console.error("Error when getting notifications: ", error);
		} finally {
			isLoading.set(false);
		}
	}

	handleNotifications.set(handleNotificationsImpl);

	$: notifications = ($messagesMapStore.get(TARGET_PRINCIPAL) || []).map(
		(notification, index) => ({
			...notification,
			uniqueId: `${notification.id || ""}-${index}`,
		}),
	);

	async function handleReactionPublish(notificationId, reaction) {
		console.log(
			`Publishing reaction for notification ${notificationId}:`,
			reaction,
		);

		try {
			const prevId = BigInt(notificationId);
			const nextId = getNextId();

			const namespace = reaction.value.namespace
				? reaction.value.namespace.value
				: "unknown";

			let pub_event = {
				id: nextId,
				prevId: [prevId],
				timestamp: BigInt(Date.now() * 1000000),
				namespace: `response.${namespace}`,
				source: Principal.fromText(TARGET_PRINCIPAL),
				data: convertToICRC16(reaction.value.data),
				headers: [],
			};
			console.log("Publishing event:", pub_event);
			let actor = client_canister_actor;
			if (!client_canister_actor) {
				actor = await client_canister();
			}

			const result = await actor.publish(pub_event);
			console.log("Reaction published:", result);
			if ("err" in result) {
				throw new Error(result.err);
			}
			return result;
		} catch (error) {
			console.error("Error publishing reaction:", error);
			throw error;
		}
	}

	function handleReaction(event) {
		console.log("Reaction event received:", event.detail);
	}

	function convertToICRC16(data) {
		if (typeof data === "string") {
			try {
				const parsedData = JSON.parse(data);
				return convertToICRC16(parsedData);
			} catch (e) {
				return { Text: data };
			}
		}

		if (typeof data !== "object" || data === null) {
			return { Text: data.toString() };
		}

		if (Array.isArray(data)) {
			return { Array: data.map(convertToICRC16) };
		}

		const convertedMap = Object.entries(data).map(([key, val]) => [
			key,
			convertToICRC16(val),
		]);
		return { Map: convertedMap };
	}
</script>

<div class="notifications-container">
	<CustomTypography variant="h4">Notifications for Principal</CustomTypography
	>
	<CustomTypography variant="body1" class="principal-id"
		>{TARGET_PRINCIPAL}</CustomTypography
	>

	{#if $isLoading}
		<CustomTypography variant="body1"
			>Loading notifications...</CustomTypography
		>
	{:else if notifications.length > 0}
		<CustomTypography variant="body1" class="notification-count">
			Total notifications: {notifications.length}
		</CustomTypography>
		<div class="card-list">
			{#each notifications as notification (notification.uniqueId)}
				<Notification
					{notification}
					on:reaction={handleReaction}
					onReactionPublish={handleReactionPublish}
				/>
			{/each}
		</div>
	{:else}
		<CustomTypography variant="body1"
			>No notifications available for this principal</CustomTypography
		>
	{/if}
</div>

<style>
	.notifications-container {
		max-width: 800px;
		margin: 0 auto;
		padding: 20px;
	}

	.card-list {
		display: flex;
		flex-direction: column;
		gap: 20px;
	}
</style>
