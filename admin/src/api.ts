export type LoginPayload = {
  email: string;
  password: string;
};

export type Market = {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  is_active: boolean;
  created_at: string;
};

export type MarketPayload = Pick<Market, "name" | "slug" | "description" | "is_active">;

export type MarketSchedule = {
  id: number;
  market_id: number;
  weekday: number;
  opens_at: string;
  closes_at: string;
  is_active: boolean;
};

export type SchedulePayload = Pick<
  MarketSchedule,
  "weekday" | "opens_at" | "closes_at" | "is_active"
>;

export type PublishedResult = {
  id: number;
  market_id: number;
  result_date: string;
  value: string;
  published_at: string;
};

export type ResultPayload = Pick<PublishedResult, "market_id" | "result_date" | "value">;
export type ResultUpdate = Pick<PublishedResult, "result_date" | "value">;

export type AuditLog = {
  id: number;
  actor_user_id: number | null;
  action: string;
  resource_type: string;
  resource_id: string | null;
  details: Record<string, unknown> | null;
  created_at: string;
};

export type StoredSession = {
  token: string;
  expiresAt: number;
};

type ErrorEnvelope = {
  error?: {
    code?: string;
    message?: string;
    details?: unknown;
  };
};

const SESSION_KEY = "matka-admin-session";
const API_BASE = (import.meta.env.VITE_API_BASE_URL || "").replace(/\/$/, "");

export class ApiError extends Error {
  status: number;
  code: string;
  details: unknown;

  constructor(message: string, status: number, code = "API_ERROR", details?: unknown) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export async function request<T>(
  path: string,
  token?: string,
  options: { method?: string; body?: unknown } = {},
): Promise<T> {
  const headers = new Headers();
  if (options.body !== undefined) headers.set("Content-Type", "application/json");
  if (token) headers.set("Authorization", `Bearer ${token}`);

  let response: Response;
  try {
    response = await fetch(`${API_BASE}${path}`, {
      method: options.method || "GET",
      headers,
      body: options.body === undefined ? undefined : JSON.stringify(options.body),
    });
  } catch {
    throw new ApiError("Cannot reach the API. Check that the backend is running.", 0, "NETWORK_ERROR");
  }

  if (response.status === 401 && token) {
    window.dispatchEvent(new Event("matka:unauthorized"));
  }
  if (response.status === 204) return undefined as T;

  const payload = (await response.json().catch(() => null)) as ErrorEnvelope | null;
  if (!response.ok) {
    throw new ApiError(
      payload?.error?.message || `Request failed (${response.status})`,
      response.status,
      payload?.error?.code,
      payload?.error?.details,
    );
  }
  return payload as T;
}

function readExpiry(token: string): number {
  try {
    const payload = token.split(".")[1];
    const base64 = payload.replace(/-/g, "+").replace(/_/g, "/");
    const claims = JSON.parse(atob(base64.padEnd(Math.ceil(base64.length / 4) * 4, "="))) as {
      exp?: unknown;
    };
    if (typeof claims.exp !== "number") throw new Error("Token has no expiry");
    return claims.exp;
  } catch {
    throw new ApiError("The API returned an invalid access token.", 500, "INVALID_TOKEN");
  }
}

export function storeSession(token: string): StoredSession {
  const session = { token, expiresAt: readExpiry(token) };
  if (session.expiresAt <= Date.now() / 1000) {
    throw new ApiError("The access token has already expired.", 401, "TOKEN_EXPIRED");
  }
  sessionStorage.setItem(SESSION_KEY, JSON.stringify(session));
  return session;
}

export function readSession(): StoredSession | null {
  try {
    const raw = sessionStorage.getItem(SESSION_KEY);
    if (!raw) return null;
    const session = JSON.parse(raw) as StoredSession;
    if (!session.token || session.expiresAt <= Date.now() / 1000) {
      clearSession();
      return null;
    }
    return session;
  } catch {
    clearSession();
    return null;
  }
}

export function clearSession(): void {
  sessionStorage.removeItem(SESSION_KEY);
}

export async function signIn(credentials: LoginPayload): Promise<string> {
  const response = await request<{ access_token: string; token_type: string }>(
    "/api/auth/login",
    undefined,
    { method: "POST", body: credentials },
  );
  return response.access_token;
}