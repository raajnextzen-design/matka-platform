import { useEffect, useState } from "react";
import {
  Activity,
  CalendarClock,
  ChevronRight,
  CircleHelp,
  FileClock,
  LayoutDashboard,
  LogOut,
  ScrollText,
  ShieldCheck,
  Store,
} from "lucide-react";

import {
  ApiError,
  clearSession,
  readSession,
  request,
  signIn,
  storeSession,
  type StoredSession,
} from "./api";
import { Toast } from "./components";
import { AuditPage, MarketsPage, OverviewPage, ResultsPage, SchedulesPage } from "./pages";

type PageKey = "overview" | "markets" | "schedules" | "results" | "audit";
type Notice = { message: string; kind: "success" | "error" };

const navigation: { id: PageKey; label: string; icon: React.ReactNode }[] = [
  { id: "overview", label: "Overview", icon: <LayoutDashboard size={18} /> },
  { id: "markets", label: "Markets", icon: <Store size={18} /> },
  { id: "schedules", label: "Schedules", icon: <CalendarClock size={18} /> },
  { id: "results", label: "Results", icon: <FileClock size={18} /> },
  { id: "audit", label: "Audit log", icon: <ScrollText size={18} /> },
];

function LoginScreen({ onSignedIn }: { onSignedIn: (session: StoredSession, email: string) => void }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [pending, setPending] = useState(false);
  const [error, setError] = useState("");

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPending(true);
    setError("");
    try {
      const token = await signIn({ email: email.trim(), password });
      const profile = await request<{ email: string; role: string }>("/api/auth/session", token);
      if (profile.role !== "admin") {
        throw new ApiError("This account does not have administrator access.", 403, "ADMIN_REQUIRED");
      }
      const session = storeSession(token);
      setPassword("");
      onSignedIn(session, profile.email);
    } catch (loginError) {
      setError(loginError instanceof Error ? loginError.message : "Sign-in failed. Try again.");
    } finally {
      setPending(false);
    }
  }

  return (
    <main className="login-screen">
      <div className="login-ambient" aria-hidden="true"><span /><span /><span /></div>
      <header className="login-brand">
        <div className="brand-emblem"><span>M</span><i /></div>
        <div><strong>MATKA<span> / </span>PLATFORM</strong><small>ADMINISTRATION</small></div>
      </header>
      <div className="login-layout">
        <section className="login-intro">
          <div className="eyebrow"><span className="gold-dot" /> PRIVATE OPERATIONS</div>
          <h1>Clear oversight.<br /><em>Every day.</em></h1>
          <p>Manage market schedules, publish results and review changes across your platform.</p>
          <div className="login-note"><ShieldCheck size={16} aria-hidden="true" /><span>Administrator access is verified by the platform API.</span></div>
        </section>
        <section className="login-form-panel">
          <div className="form-panel-top"><span>SECURE SIGN IN</span><span>01 <i>/</i> AUTH</span></div>
          <h2>Welcome back</h2>
          <p>Sign in with your administrator account.</p>
          <form className="form-stack login-form" onSubmit={submit}>
            {error && <div className="form-error" role="alert">{error}</div>}
            <label className="field"><span>Email address</span><input type="email" autoComplete="username" autoFocus required value={email} onChange={(event) => setEmail(event.target.value)} placeholder="admin@example.com" /></label>
            <label className="field"><span>Password</span><input type="password" autoComplete="current-password" required value={password} onChange={(event) => setPassword(event.target.value)} placeholder="Enter your password" /></label>
            <button className="button button-primary login-submit" type="submit" disabled={pending}>{pending ? <><span className="button-spinner" /> Verifying access…</> : <>Continue <ChevronRight size={17} aria-hidden="true" /></>}</button>
          </form>
          <div className="login-form-foot"><span className="tiny-lock" /> Credentials are sent only to your configured API.</div>
        </section>
      </div>
      <footer className="login-footer"><span>MATKA PLATFORM ADMIN</span><span>NO WAGERING OR PAYMENT OPERATIONS</span><span>LOCAL-FIRST CONSOLE</span></footer>
    </main>
  );
}

function DashboardShell({
  session,
  email,
  page,
  onPage,
  onSignOut,
  revision,
  onChanged,
}: {
  session: StoredSession;
  email: string;
  page: PageKey;
  onPage: (page: PageKey) => void;
  onSignOut: () => void;
  revision: number;
  onChanged: (message: string) => void;
}) {
  const [apiStatus, setApiStatus] = useState<"checking" | "online" | "offline">("checking");
  const pageTitles: Record<PageKey, string> = {
    overview: "Overview",
    markets: "Market catalog",
    schedules: "Weekly schedules",
    results: "Result publishing",
    audit: "Change history",
  };

  useEffect(() => {
    let current = true;
    async function checkHealth() {
      try {
        await request<{ status: string }>("/health");
        if (current) setApiStatus("online");
      } catch {
        if (current) setApiStatus("offline");
      }
    }
    void checkHealth();
    const timer = window.setInterval(() => void checkHealth(), 30_000);
    return () => { current = false; window.clearInterval(timer); };
  }, []);

  function renderPage() {
    if (page === "markets") return <MarketsPage token={session.token} revision={revision} onChanged={onChanged} />;
    if (page === "schedules") return <SchedulesPage token={session.token} revision={revision} onChanged={onChanged} />;
    if (page === "results") return <ResultsPage token={session.token} revision={revision} onChanged={onChanged} />;
    if (page === "audit") return <AuditPage token={session.token} revision={revision} onChanged={onChanged} />;
    return <OverviewPage token={session.token} revision={revision} onChanged={onChanged} onNavigate={() => onPage("markets")} />;
  }

  return (
    <div className="dashboard-shell">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="brand-emblem brand-emblem-small"><span>M</span><i /></div>
          <div><strong>MATKA<span> / </span>PLATFORM</strong><small>ADMIN CONSOLE</small></div>
        </div>
        <div className="nav-caption">WORKSPACE</div>
        <nav className="primary-nav" aria-label="Primary navigation">
          {navigation.map((item, index) => (
            <button key={item.id} type="button" className={`nav-item ${page === item.id ? "nav-active" : ""}`} onClick={() => onPage(item.id)} aria-current={page === item.id ? "page" : undefined}>
              <span className="nav-icon">{item.icon}</span><span>{item.label}</span>{page === item.id && <span className="nav-index">0{index + 1}</span>}
            </button>
          ))}
        </nav>
        <div className="sidebar-bottom">
          <div className="sidebar-mission"><div className="mission-mark"><Activity size={16} /></div><div><strong>Operations mode</strong><span>Informational platform</span></div></div>
          <div className="sidebar-footer-row"><span>BUILD 0.1.0</span><button type="button" className="icon-button sidebar-help" aria-label="Open help information" title="API setup information" onClick={() => window.dispatchEvent(new CustomEvent("matka:help"))}><CircleHelp size={16} /></button></div>
        </div>
      </aside>
      <main className="main-column">
        <header className="topbar">
          <div className="breadcrumbs"><span>Workspace</span><ChevronRight size={14} aria-hidden="true" /><strong>{pageTitles[page]}</strong></div>
          <div className="topbar-actions">
            <span className={`api-indicator api-${apiStatus}`}><i />{apiStatus === "online" ? "API CONNECTED" : apiStatus === "offline" ? "API OFFLINE" : "CHECKING API"}</span>
            <span className="topbar-divider" />
            <div className="account-chip"><div className="account-avatar">{email.slice(0, 1).toUpperCase() || "A"}</div><div className="account-details"><strong>Administrator</strong><span>{email}</span></div><button className="icon-button signout-button" type="button" onClick={onSignOut} title="Sign out" aria-label="Sign out"><LogOut size={16} /></button></div>
          </div>
        </header>
        <div className="page-content" key={page}>
          <div className="page-topline"><span>OPERATIONS / 2026</span><span className="page-topline-right">ACCESS LEVEL <strong>ADMIN</strong></span></div>
          {renderPage()}
        </div>
        <footer className="app-footer"><span>MATKA PLATFORM <i>•</i> ADMINISTRATOR CONSOLE</span><span>MARKET DATA IS INFORMATIONAL ONLY</span></footer>
      </main>
    </div>
  );
}

export default function App() {
  const [session, setSession] = useState<StoredSession | null>(() => readSession());
  const [adminEmail, setAdminEmail] = useState("");
  const [page, setPage] = useState<PageKey>("overview");
  const [revision, setRevision] = useState(0);
  const [notice, setNotice] = useState<Notice | null>(null);
  const [helpOpen, setHelpOpen] = useState(false);

  useEffect(() => {
    if (!session) return;
    const remaining = session.expiresAt * 1000 - Date.now();
    if (remaining <= 0) {
      clearSession();
      setSession(null);
      setNotice({ message: "Your session expired. Sign in again.", kind: "error" });
      return;
    }
    const timer = window.setTimeout(() => {
      clearSession();
      setSession(null);
      setNotice({ message: "Your session expired. Sign in again.", kind: "error" });
    }, Math.min(remaining, 2_147_000_000));
    return () => window.clearTimeout(timer);
  }, [session]);

  useEffect(() => {
    function expireSession() {
      clearSession();
      setSession(null);
      setAdminEmail("");
      setNotice({ message: "Your session is no longer valid. Sign in again.", kind: "error" });
    }
    function openHelp() { setHelpOpen(true); }
    window.addEventListener("matka:unauthorized", expireSession);
    window.addEventListener("matka:help", openHelp);
    return () => {
      window.removeEventListener("matka:unauthorized", expireSession);
      window.removeEventListener("matka:help", openHelp);
    };
  }, []);

  useEffect(() => {
    if (!notice) return;
    const timer = window.setTimeout(() => setNotice(null), 4_500);
    return () => window.clearTimeout(timer);
  }, [notice]);

  useEffect(() => {
    if (!session) return;
    let current = true;
    request<{ email: string; role: string }>("/api/auth/session", session.token)
      .then((profile) => {
        if (current && profile.role === "admin") setAdminEmail(profile.email);
        else if (current) {
          clearSession();
          setSession(null);
          setNotice({ message: "This account does not have administrator access.", kind: "error" });
        }
      })
      .catch(() => {
        if (current) {
          clearSession();
          setSession(null);
        }
      });
    return () => { current = false; };
  }, [session]);

  async function handleSignIn(nextSession: StoredSession, email: string) {
    setSession(nextSession);
    setAdminEmail(email);
    setPage("overview");
    setNotice({ message: "Administrator session verified", kind: "success" });
  }

  function handleSignOut() {
    clearSession();
    setSession(null);
    setAdminEmail("");
    setNotice({ message: "Signed out securely", kind: "success" });
  }

  function handleChanged(message: string) {
    setRevision((value) => value + 1);
    setNotice({ message, kind: "success" });
  }

  return (
    <>
      {session ? (
        <DashboardShell session={session} email={adminEmail} page={page} onPage={setPage} onSignOut={handleSignOut} revision={revision} onChanged={handleChanged} />
      ) : <LoginScreen onSignedIn={handleSignIn} />}
      {notice && <Toast message={notice.message} kind={notice.kind} onClose={() => setNotice(null)} />}
      {helpOpen && (
        <div className="help-popover" role="dialog" aria-label="API connection help">
          <button className="icon-button" type="button" onClick={() => setHelpOpen(false)} aria-label="Close help">×</button>
          <strong>API connection</strong>
          <p>Start FastAPI at <code>127.0.0.1:8000</code> or set <code>VITE_API_PROXY_TARGET</code> in <code>admin/.env.local</code>.</p>
        </div>
      )}
    </>
  );
}