import { writable } from "svelte/store";
import { AuthClient } from "@dfinity/auth-client";
import { browser } from "$app/environment";
import { Actor, HttpAgent } from "@dfinity/agent";
import { idlFactory as dao } from "./dao.did";
import { idlFactory as _client } from "./client.did";
import { idlFactory as _broadcaster } from "./broadcaster.did";

if (typeof global === "undefined") {
  window.global = window;
}

export const principalId = writable("");
export const isAuthenticated = writable(false);

export let client_canister_actor = null;
export let CANISTER_ID_EVENT_XPERIENCE_BACKEND =
  process.env.CANISTER_ID_EVENT_XPERIENCE_BACKEND;

export let broadcaster_canister_actor = null;
export const broadcaster_canister = "rvrj4-pyaaa-aaaal-ajluq-cai";

export let dao_canister_actor = null;
export const dao_canister = "k5yym-uqaaa-aaaal-ajoyq-cai";

const isLocal = process.env.DFX_NETWORK == "local";
const agentHost = isLocal ? "http://localhost:4943" : "https://icp0.io";

async function initializeAuthClient() {
  if (!browser) return;

  const authClient = await AuthClient.create();

  if (await authClient.isAuthenticated()) {
    isAuthenticated.set(true);
    const identity = authClient.getIdentity();
    principalId.set(identity.getPrincipal().toText());
  }
}

export async function loginII() {
  if (!browser) return;

  const authClient = await AuthClient.create();
  const iiUrl =
    process.env.DFX_NETWORK == "ic"
      ? "https://identity.icp0.io"
      : `http://${process.env.CANISTER_ID_INTERNET_IDENTITY}.localhost:4943`;

  await authClient.login({
    identityProvider: iiUrl,
    onSuccess: () => {
      isAuthenticated.set(true);
      const identity = authClient.getIdentity();
      principalId.set(identity.getPrincipal().toText());
    },
    onError: () => {
      isAuthenticated.set(false);
    },
  });
}

export function logout() {
  if (!browser) return;

  localStorage.removeItem("ic-delegation");
  localStorage.removeItem("ic-identity");
  isAuthenticated.set(false);
  principalId.set("");
}

if (browser) {
  initializeAuthClient();
}

export async function dao_backend() {
  const agent = HttpAgent.createSync({ host: "https://icp0.io" });

  if (isLocal) {
    agent.fetchRootKey().catch((err) => {
      console.log("Error fetching root key: ", err);
    });
  }
  return Actor.createActor(dao, { agent, canisterId: dao_canister });
}

export async function broadcaster() {
  const agent = HttpAgent.createSync({ host: "https://icp0.io" });

  if (isLocal) {
    agent.fetchRootKey().catch((err) => {
      console.log("Error fetching root key: ", err);
    });
  }
  return Actor.createActor(_broadcaster, {
    agent,
    canisterId: broadcaster_canister,
  });
}

export async function client_canister() {
  const agent = HttpAgent.createSync({ host: agentHost });

  if (isLocal) {
    agent.fetchRootKey().catch((err) => {
      console.log("Error fetching root key: ", err);
    });
  }
  return Actor.createActor(_client, {
    agent,
    canisterId: CANISTER_ID_EVENT_XPERIENCE_BACKEND,
  });
}
