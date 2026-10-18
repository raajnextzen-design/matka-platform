import { useEffect, useState } from "react";
import {
  ArrowDownUp,
  ArrowUpRight,
  CalendarDays,
  Check,
  Clock3,
  FilePlus2,
  History,
  Pencil,
  Plus,
  Search,
  Send,
  ToggleLeft,
  ToggleRight,
  Trash2,
} from "lucide-react";

import {
  request,
  type AuditLog,
  type Market,
  type MarketPayload,
  type MarketSchedule,
  type PublishedResult,
  type ResultPayload,
  type SchedulePayload,
} from "./api";
import { EmptyState, ErrorState, LoadingState, Modal, PageHeading, StatusBadge, TableEmpty } from "./components";

type PageProps = {
  token: string;
  revision: number;
  onChanged: (message: string) => void;
};

const weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

function messageFrom(error: unknown): string {
  return error instanceof Error ? error.message : "Something unexpected happened.";
}

function formattedDate(value: string, options?: Intl.DateTimeFormatOptions): string {
  const date = new Date(value.includes("T") ? value : `${value}T00:00:00`);
  if (Number.isNaN(date.getTime())) return value;
  return new Intl.DateTimeFormat(undefined, options || { day: "2-digit", month: "short", year: "numeric" }).format(date);
}

function todayInputValue(): string {
  const date = new Date();
  const localDate = new Date(date.getTime() - date.getTimezoneOffset() * 60_000);
  return localDate.toISOString().slice(0, 10);
}

function ResultNumber({ value }: { value: string }) {
  return <span className="result-number">{value}</span>;
}

function ResultRows({ results, markets }: { results: PublishedResult[]; markets: Market[] }) {
  const marketNames = new Map(markets.map((market) => [market.id, market.name]));
  return results.map((result) => (
    <tr key={result.id}>
      <td><span className="table-primary">{marketNames.get(result.market_id) || `Market ${result.market_id}`}</span></td>
      <td><ResultNumber value={result.value} /></td>
      <td>{formattedDate(result.result_date)}</td>
      <td className="muted-cell">{formattedDate(result.published_at, { hour: "2-digit", minute: "2-digit" })}</td>
    </tr>
  ));
}

export function OverviewPage({ token, revision, onChanged, onNavigate }: PageProps & { onNavigate: () => void }) {
  const [markets, setMarkets] = useState<Market[]>([]);
  const [results, setResults] = useState<PublishedResult[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    let current = true;
    setLoading(true);
    setError("");
    Promise.all([
      request<Market[]>("/api/admin/markets", token),
      request<PublishedResult[]>("/api/admin/results", token),
    ])
      .then(([marketRows, resultRows]) => {
        if (!current) return;
        setMarkets(marketRows);
        setResults(resultRows);
      })
      .catch((loadError: unknown) => {
        if (current) setError(messageFrom(loadError));
      })
      .finally(() => {
        if (current) setLoading(false);
      });
    return () => { current = false; };
  }, [token, revision, attempt]);

  const activeCount = markets.filter((market) => market.is_active).length;
  const pausedCount = markets.length - activeCount;
  const latest = results.slice(0, 6);

  return (
    <>
      <PageHeading
        eyebrow="Operations / Overview"
        title="Control room"
        description="A live operational view of markets and published results."
        action={(
          <button className="button button-secondary" onClick={() => onChanged("Overview refreshed")} type="button">
            <ArrowDownUp size={15} aria-hidden="true" /> Refresh data
          </button>
        )}
      />
      {loading ? <LoadingState label="Loading overview" /> : error ? (
        <ErrorState message={error} onRetry={() => setAttempt((value) => value + 1)} />
      ) : (
        <>
          <section className="stats-grid" aria-label="Market and result counts">
            <article className="stat-card stat-card-featured">
              <div className="stat-topline"><span>Markets in system</span><span className="stat-index">01 / 03</span></div>
              <div className="stat-value">{markets.length.toString().padStart(2, "0")}</div>
              <div className="stat-foot"><span className="gold-dot" /> Total market records</div>
            </article>
            <article className="stat-card">
              <div className="stat-topline"><span>Active markets</span><ToggleRight size={17} aria-hidden="true" /></div>
              <div className="stat-value">{activeCount.toString().padStart(2, "0")}</div>
              <div className="stat-foot"><span className="status-indicator status-indicator-live" /> Available to users</div>
            </article>
            <article className="stat-card">
              <div className="stat-topline"><span>Paused markets</span><ToggleLeft size={17} aria-hidden="true" /></div>
              <div className="stat-value">{pausedCount.toString().padStart(2, "0")}</div>
              <div className="stat-foot">Hidden from public listings</div>
            </article>
            <article className="stat-card">
              <div className="stat-topline"><span>Published results</span><History size={17} aria-hidden="true" /></div>
              <div className="stat-value">{results.length.toString().padStart(2, "0")}</div>
              <div className="stat-foot">Historical result records</div>
            </article>
          </section>

          <div className="overview-grid">
            <section className="content-panel results-panel">
              <div className="panel-heading">
                <div>
                  <div className="eyebrow">Latest activity</div>
                  <h2>Published results</h2>
                </div>
                <span className="panel-count">{results.length} total</span>
              </div>
              {latest.length === 0 ? <EmptyState title="No results published" description="Published market results will appear here." /> : (
                <div className="table-wrap">
                  <table>
                    <thead><tr><th>Market</th><th>Result</th><th>Result date</th><th>Published</th></tr></thead>
                    <tbody><ResultRows results={latest} markets={markets} /></tbody>
                  </table>
                </div>
              )}
            </section>
            <aside className="overview-aside">
              <div className="aside-kicker"><span className="live-pulse" /> SYSTEM SNAPSHOT</div>
              <div className="aside-rule" />
              <div className="snapshot-row"><span>Operational markets</span><strong>{activeCount} <small>/ {markets.length}</small></strong></div>
              <div className="snapshot-row"><span>Paused for review</span><strong>{pausedCount}</strong></div>
              <div className="snapshot-row"><span>Last result record</span><strong>{latest[0] ? formattedDate(latest[0].published_at, { day: "2-digit", month: "short" }) : "—"}</strong></div>
              <button className="aside-link" onClick={onNavigate} type="button">
                Manage markets <ArrowUpRight size={15} aria-hidden="true" />
              </button>
              <div className="aside-index">M / P <span>PLATFORM OPERATIONS</span></div>
            </aside>
          </div>
        </>
      )}
    </>
  );
}

function MarketDialog({
  token,
  market,
  onClose,
  onSaved,
}: {
  token: string;
  market: Market | null;
  onClose: () => void;
  onSaved: (message: string) => void;
}) {
  const [name, setName] = useState(market?.name || "");
  const [slug, setSlug] = useState(market?.slug || "");
  const [description, setDescription] = useState(market?.description || "");
  const [active, setActive] = useState(market?.is_active ?? true);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState("");

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPending(true);
    setError("");
    const payload: MarketPayload = { name: name.trim(), slug: slug.trim(), description: description.trim() || null, is_active: active };
    try {
      await request<Market>(market ? `/api/admin/markets/${market.id}` : "/api/admin/markets", token, {
        method: market ? "PATCH" : "POST",
        body: payload,
      });
      onSaved(market ? "Market details saved" : "Market created");
    } catch (saveError) {
      setError(messageFrom(saveError));
    } finally {
      setPending(false);
    }
  }

  return (
    <Modal title={market ? "Edit market" : "Create market"} description="Market details are visible to users when the market is active." onClose={onClose}>
      <form className="form-stack" onSubmit={submit}>
        {error && <div className="form-error" role="alert">{error}</div>}
        <label className="field"><span>Market name</span><input autoFocus maxLength={120} required value={name} onChange={(event) => setName(event.target.value)} placeholder="e.g. Morning Market" /></label>
        <label className="field"><span>URL slug</span><input maxLength={80} pattern="[a-z0-9]+(-[a-z0-9]+)*" required value={slug} onChange={(event) => setSlug(event.target.value.toLowerCase())} placeholder="morning-market" /><small>Lowercase letters, numbers and hyphens.</small></label>
        <label className="field"><span>Description <em>Optional</em></span><textarea maxLength={500} rows={3} value={description} onChange={(event) => setDescription(event.target.value)} placeholder="A short operational description" /></label>
        <label className="toggle-field"><span><strong>Market status</strong><small>{active ? "Visible in public listings" : "Hidden from public listings"}</small></span><input type="checkbox" checked={active} onChange={(event) => setActive(event.target.checked)} /><span className="switch-track" aria-hidden="true" /></label>
        <div className="form-actions">
          <button className="button button-quiet" type="button" onClick={onClose}>Cancel</button>
          <button className="button button-primary" type="submit" disabled={pending}>{pending ? "Saving…" : market ? "Save changes" : "Create market"}</button>
        </div>
      </form>
    </Modal>
  );
}

export function MarketsPage({ token, revision, onChanged }: PageProps) {
  const [markets, setMarkets] = useState<Market[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [attempt, setAttempt] = useState(0);
  const [query, setQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<"all" | "active" | "paused">("all");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<Market | null>(null);
  const [updatingId, setUpdatingId] = useState<number | null>(null);

  useEffect(() => {
    let current = true;
    setLoading(true);
    setError("");
    request<Market[]>("/api/admin/markets", token)
      .then((rows) => { if (current) setMarkets(rows); })
      .catch((loadError: unknown) => { if (current) setError(messageFrom(loadError)); })
      .finally(() => { if (current) setLoading(false); });
    return () => { current = false; };
  }, [token, revision, attempt]);

  const visibleMarkets = markets.filter((market) => {
    const matchesQuery = `${market.name} ${market.slug}`.toLowerCase().includes(query.toLowerCase());
    const matchesStatus = statusFilter === "all" || (statusFilter === "active" ? market.is_active : !market.is_active);
    return matchesQuery && matchesStatus;
  });

  function openCreate() {
    setEditing(null);
    setDialogOpen(true);
  }

  function saved(message: string) {
    setDialogOpen(false);
    onChanged(message);
  }

  async function toggleMarket(market: Market) {
    setUpdatingId(market.id);
    try {
      await request<Market>(`/api/admin/markets/${market.id}`, token, {
        method: "PATCH",
        body: { is_active: !market.is_active },
      });
      onChanged(market.is_active ? "Market paused" : "Market activated");
    } catch (toggleError) {
      setError(messageFrom(toggleError));
    } finally {
      setUpdatingId(null);
    }
  }

  return (
    <>
      <PageHeading eyebrow="Catalog / Markets" title="Markets" description="Create markets, update operational details and control public visibility." action={<button className="button button-primary" onClick={openCreate} type="button"><Plus size={16} aria-hidden="true" /> New market</button>} />
      <section className="content-panel">
        <div className="toolbar">
          <label className="search-field"><Search size={16} aria-hidden="true" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search markets" aria-label="Search markets" /></label>
          <div className="segmented-control" role="group" aria-label="Filter markets by status">
            {(["all", "active", "paused"] as const).map((filter) => <button key={filter} className={statusFilter === filter ? "selected" : ""} onClick={() => setStatusFilter(filter)} type="button">{filter === "all" ? "All" : filter === "active" ? "Active" : "Paused"}</button>)}
          </div>
          <span className="toolbar-count">{visibleMarkets.length} RECORDS</span>
        </div>
        {loading ? <LoadingState label="Loading markets" /> : error ? <ErrorState message={error} onRetry={() => setAttempt((value) => value + 1)} /> : (
          <div className="table-wrap">
            <table>
              <thead><tr><th>Market</th><th>Slug</th><th>Status</th><th>Created</th><th className="align-right">Actions</th></tr></thead>
              <tbody>
                {visibleMarkets.length === 0 ? <TableEmpty columns={5} message={markets.length ? "No markets match these filters." : "No markets have been created yet."} /> : visibleMarkets.map((market) => (
                  <tr key={market.id}>
                    <td><span className="table-primary">{market.name}</span><span className="table-secondary">{market.description || "No description"}</span></td>
                    <td><code className="slug-code">/{market.slug}</code></td>
                    <td><StatusBadge active={market.is_active} /></td>
                    <td>{formattedDate(market.created_at)}</td>
                    <td className="align-right action-cell">
                      <button className="icon-button" type="button" onClick={() => { setEditing(market); setDialogOpen(true); }} title={`Edit ${market.name}`} aria-label={`Edit ${market.name}`}><Pencil size={16} /></button>
                      <button className="icon-button" type="button" onClick={() => void toggleMarket(market)} disabled={updatingId === market.id} title={market.is_active ? "Pause market" : "Activate market"} aria-label={market.is_active ? `Pause ${market.name}` : `Activate ${market.name}`}>{market.is_active ? <ToggleRight size={19} /> : <ToggleLeft size={19} />}</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
      {dialogOpen && <MarketDialog token={token} market={editing} onClose={() => setDialogOpen(false)} onSaved={saved} />}
    </>
  );
}

function ScheduleDialog({
  token,
  marketId,
  schedule,
  onClose,
  onSaved,
}: {
  token: string;
  marketId: number;
  schedule: MarketSchedule | null;
  onClose: () => void;
  onSaved: (message: string) => void;
}) {
  const [weekday, setWeekday] = useState(String(schedule?.weekday ?? 0));
  const [opensAt, setOpensAt] = useState(schedule?.opens_at.slice(0, 5) || "09:00");
  const [closesAt, setClosesAt] = useState(schedule?.closes_at.slice(0, 5) || "17:00");
  const [active, setActive] = useState(schedule?.is_active ?? true);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState("");

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPending(true);
    setError("");
    const payload: SchedulePayload = { weekday: Number(weekday), opens_at: opensAt, closes_at: closesAt, is_active: active };
    try {
      await request<MarketSchedule>(schedule ? `/api/admin/schedules/${schedule.id}` : `/api/admin/markets/${marketId}/schedules`, token, {
        method: schedule ? "PATCH" : "POST",
        body: payload,
      });
      onSaved(schedule ? "Schedule updated" : "Schedule added");
    } catch (saveError) {
      setError(messageFrom(saveError));
    } finally {
      setPending(false);
    }
  }

  return (
    <Modal title={schedule ? "Edit schedule" : "Add schedule"} description="One schedule is supported for each weekday." onClose={onClose}>
      <form className="form-stack" onSubmit={submit}>
        {error && <div className="form-error" role="alert">{error}</div>}
        <label className="field"><span>Weekday</span><select value={weekday} onChange={(event) => setWeekday(event.target.value)}>{weekdays.map((day, index) => <option key={day} value={index}>{day}</option>)}</select></label>
        <div className="field-row">
          <label className="field"><span>Opens at</span><input type="time" required value={opensAt} onChange={(event) => setOpensAt(event.target.value)} /></label>
          <label className="field"><span>Closes at</span><input type="time" required value={closesAt} onChange={(event) => setClosesAt(event.target.value)} /></label>
        </div>
        <label className="toggle-field"><span><strong>Schedule status</strong><small>{active ? "Shown to users" : "Hidden from users"}</small></span><input type="checkbox" checked={active} onChange={(event) => setActive(event.target.checked)} /><span className="switch-track" aria-hidden="true" /></label>
        <div className="form-actions"><button className="button button-quiet" type="button" onClick={onClose}>Cancel</button><button className="button button-primary" type="submit" disabled={pending}>{pending ? "Saving…" : schedule ? "Save schedule" : "Add schedule"}</button></div>
      </form>
    </Modal>
  );
}

export function SchedulesPage({ token, revision, onChanged }: PageProps) {
  const [markets, setMarkets] = useState<Market[]>([]);
  const [selectedId, setSelectedId] = useState("");
  const [schedules, setSchedules] = useState<MarketSchedule[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [attempt, setAttempt] = useState(0);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<MarketSchedule | null>(null);
  const [deletingId, setDeletingId] = useState<number | null>(null);

  useEffect(() => {
    let current = true;
    request<Market[]>("/api/admin/markets", token)
      .then((rows) => {
        if (!current) return;
        setMarkets(rows);
        setSelectedId((selected) => selected || (rows[0] ? String(rows[0].id) : ""));
      })
      .catch((loadError: unknown) => { if (current) setError(messageFrom(loadError)); });
    return () => { current = false; };
  }, [token, revision]);

  useEffect(() => {
    if (!selectedId) {
      setSchedules([]);
      setLoading(false);
      return;
    }
    let current = true;
    setLoading(true);
    setError("");
    request<MarketSchedule[]>(`/api/admin/markets/${selectedId}/schedules`, token)
      .then((rows) => { if (current) setSchedules(rows); })
      .catch((loadError: unknown) => { if (current) setError(messageFrom(loadError)); })
      .finally(() => { if (current) setLoading(false); });
    return () => { current = false; };
  }, [token, selectedId, revision, attempt]);

  async function removeSchedule(schedule: MarketSchedule) {
    if (!window.confirm(`Remove the ${weekdays[schedule.weekday]} schedule?`)) return;
    setDeletingId(schedule.id);
    try {
      await request<void>(`/api/admin/schedules/${schedule.id}`, token, { method: "DELETE" });
      onChanged("Schedule removed");
    } catch (deleteError) {
      setError(messageFrom(deleteError));
    } finally {
      setDeletingId(null);
    }
  }

  const selectedMarket = markets.find((market) => String(market.id) === selectedId);
  function saved(message: string) {
    setDialogOpen(false);
    onChanged(message);
  }

  return (
    <>
      <PageHeading eyebrow="Catalog / Schedules" title="Market schedules" description="Set the weekly operating window for each market." action={<label className="market-select-label"><span>Selected market</span><select value={selectedId} onChange={(event) => setSelectedId(event.target.value)} disabled={!markets.length}>{markets.length ? markets.map((market) => <option value={market.id} key={market.id}>{market.name}</option>) : <option value="">No markets</option>}</select></label>} />
      <section className="content-panel">
        <div className="panel-heading schedules-toolbar">
          <div><div className="eyebrow">Weekly hours</div><h2>{selectedMarket?.name || "Choose a market"}</h2></div>
          <button className="button button-primary" type="button" disabled={!selectedId} onClick={() => { setEditing(null); setDialogOpen(true); }}><Plus size={16} aria-hidden="true" /> Add schedule</button>
        </div>
        {error && !loading ? <ErrorState message={error} onRetry={() => setAttempt((value) => value + 1)} /> : loading ? <LoadingState label="Loading schedules" /> : !markets.length ? <EmptyState title="Create a market first" description="Schedules are attached to an existing market." /> : (
          <div className="table-wrap">
            <table>
              <thead><tr><th>Weekday</th><th>Opening time</th><th>Closing time</th><th>Status</th><th className="align-right">Actions</th></tr></thead>
              <tbody>{schedules.length === 0 ? <TableEmpty columns={5} message="No weekly schedules are configured for this market." /> : [...schedules].sort((a, b) => a.weekday - b.weekday).map((schedule) => (
                <tr key={schedule.id}>
                  <td><span className="table-primary">{weekdays[schedule.weekday]}</span></td>
                  <td><span className="time-value"><Clock3 size={14} aria-hidden="true" />{schedule.opens_at.slice(0, 5)}</span></td>
                  <td><span className="time-value"><Clock3 size={14} aria-hidden="true" />{schedule.closes_at.slice(0, 5)}</span></td>
                  <td><StatusBadge active={schedule.is_active} /></td>
                  <td className="align-right action-cell">
                    <button className="icon-button" type="button" onClick={() => { setEditing(schedule); setDialogOpen(true); }} title="Edit schedule" aria-label={`Edit ${weekdays[schedule.weekday]} schedule`}><Pencil size={16} /></button>
                    <button className="icon-button icon-danger" type="button" onClick={() => void removeSchedule(schedule)} disabled={deletingId === schedule.id} title="Remove schedule" aria-label={`Remove ${weekdays[schedule.weekday]} schedule`}><Trash2 size={16} /></button>
                  </td>
                </tr>
              ))}</tbody>
            </table>
          </div>
        )}
        <div className="panel-footnote"><CalendarDays size={14} aria-hidden="true" /> Weekday numbering follows the API schema: Monday 0 through Sunday 6.</div>
      </section>
      {dialogOpen && selectedId && <ScheduleDialog token={token} marketId={Number(selectedId)} schedule={editing} onClose={() => setDialogOpen(false)} onSaved={saved} />}
    </>
  );
}

function ResultDialog({
  token,
  markets,
  result,
  onClose,
  onSaved,
}: {
  token: string;
  markets: Market[];
  result: PublishedResult | null;
  onClose: () => void;
  onSaved: (message: string) => void;
}) {
  const [marketId, setMarketId] = useState(String(result?.market_id || markets[0]?.id || ""));
  const [resultDate, setResultDate] = useState(result?.result_date || todayInputValue());
  const [value, setValue] = useState(result?.value || "");
  const [pending, setPending] = useState(false);
  const [error, setError] = useState("");

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPending(true);
    setError("");
    const payload: ResultPayload = { market_id: Number(marketId), result_date: resultDate, value: value.trim() };
    try {
      if (result) {
        await request<PublishedResult>(`/api/admin/results/${result.id}`, token, {
          method: "PATCH",
          body: { result_date: payload.result_date, value: payload.value },
        });
        onSaved("Published result updated");
      } else {
        await request<PublishedResult>("/api/admin/results", token, { method: "POST", body: payload });
        onSaved("Result published");
      }
    } catch (saveError) {
      setError(messageFrom(saveError));
    } finally {
      setPending(false);
    }
  }

  return (
    <Modal title={result ? "Correct result" : "Publish result"} description={result ? "Changes are recorded in the admin audit log." : "Publishing makes this result visible to users immediately."} onClose={onClose}>
      <form className="form-stack" onSubmit={submit}>
        {error && <div className="form-error" role="alert">{error}</div>}
        <label className="field"><span>Market</span><select required value={marketId} onChange={(event) => setMarketId(event.target.value)} disabled={Boolean(result)}>{(result ? markets : markets.filter((market) => market.is_active)).map((market) => <option key={market.id} value={market.id}>{market.name}{market.is_active ? "" : " · paused"}</option>)}</select></label>
        <label className="field"><span>Result date</span><input type="date" required value={resultDate} onChange={(event) => setResultDate(event.target.value)} /></label>
        <label className="field"><span>Published value</span><input maxLength={64} required value={value} onChange={(event) => setValue(event.target.value)} placeholder="Enter the published result" /><small>Text format follows your market's result convention.</small></label>
        <div className="form-actions"><button className="button button-quiet" type="button" onClick={onClose}>Cancel</button><button className="button button-primary" type="submit" disabled={pending || (!result && !markets.some((market) => market.is_active))}>{pending ? "Saving…" : result ? "Save correction" : <><Send size={15} aria-hidden="true" /> Publish result</>}</button></div>
      </form>
    </Modal>
  );
}

export function ResultsPage({ token, revision, onChanged }: PageProps) {
  const [markets, setMarkets] = useState<Market[]>([]);
  const [results, setResults] = useState<PublishedResult[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [attempt, setAttempt] = useState(0);
  const [query, setQuery] = useState("");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<PublishedResult | null>(null);

  useEffect(() => {
    let current = true;
    setLoading(true);
    setError("");
    Promise.all([
      request<Market[]>("/api/admin/markets", token),
      request<PublishedResult[]>("/api/admin/results", token),
    ])
      .then(([marketRows, resultRows]) => {
        if (!current) return;
        setMarkets(marketRows);
        setResults(resultRows);
      })
      .catch((loadError: unknown) => { if (current) setError(messageFrom(loadError)); })
      .finally(() => { if (current) setLoading(false); });
    return () => { current = false; };
  }, [token, revision, attempt]);

  const marketNames = new Map(markets.map((market) => [market.id, market.name]));
  const visibleResults = results.filter((result) => `${result.value} ${marketNames.get(result.market_id) || ""} ${result.result_date}`.toLowerCase().includes(query.toLowerCase()));

  async function deleteResult(result: PublishedResult) {
    if (!window.confirm("Delete this published result? This action is recorded in the audit log.")) return;
    try {
      await request<void>(`/api/admin/results/${result.id}`, token, { method: "DELETE" });
      onChanged("Published result deleted");
    } catch (deleteError) {
      setError(messageFrom(deleteError));
    }
  }

  function saved(message: string) {
    setDialogOpen(false);
    onChanged(message);
  }

  return (
    <>
      <PageHeading eyebrow="Publishing / Results" title="Result history" description="Review published values, correct a record or publish a new result." action={<button className="button button-primary" type="button" onClick={() => { setEditing(null); setDialogOpen(true); }} disabled={!markets.some((market) => market.is_active)}><FilePlus2 size={16} aria-hidden="true" /> Publish result</button>} />
      <section className="content-panel">
        <div className="toolbar">
          <label className="search-field"><Search size={16} aria-hidden="true" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search value, market or date" aria-label="Search published results" /></label>
          <span className="toolbar-count"><History size={14} aria-hidden="true" /> {results.length} PUBLISHED</span>
        </div>
        {loading ? <LoadingState label="Loading result history" /> : error ? <ErrorState message={error} onRetry={() => setAttempt((value) => value + 1)} /> : (
          <div className="table-wrap">
            <table>
              <thead><tr><th>Market</th><th>Published result</th><th>Result date</th><th>Published at</th><th className="align-right">Actions</th></tr></thead>
              <tbody>{visibleResults.length === 0 ? <TableEmpty columns={5} message={results.length ? "No published results match this search." : "No results have been published yet."} /> : visibleResults.map((result) => (
                <tr key={result.id}>
                  <td><span className="table-primary">{marketNames.get(result.market_id) || `Market ${result.market_id}`}</span></td>
                  <td><ResultNumber value={result.value} /></td>
                  <td>{formattedDate(result.result_date)}</td>
                  <td className="muted-cell">{formattedDate(result.published_at, { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" })}</td>
                  <td className="align-right action-cell">
                    <button className="icon-button" type="button" onClick={() => { setEditing(result); setDialogOpen(true); }} title="Correct result" aria-label={`Correct result for ${marketNames.get(result.market_id) || "market"}`}><Pencil size={16} /></button>
                    <button className="icon-button icon-danger" type="button" onClick={() => void deleteResult(result)} title="Delete result" aria-label={`Delete result ${result.value}`}><Trash2 size={16} /></button>
                  </td>
                </tr>
              ))}</tbody>
            </table>
          </div>
        )}
        <div className="panel-footnote"><Check size={14} aria-hidden="true" /> Published records are immediately available through the public results API.</div>
      </section>
      {dialogOpen && <ResultDialog token={token} markets={markets} result={editing} onClose={() => setDialogOpen(false)} onSaved={saved} />}
    </>
  );
}

export function AuditPage({ token, revision }: PageProps) {
  const [entries, setEntries] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    let current = true;
    setLoading(true);
    setError("");
    request<AuditLog[]>("/api/admin/audit-logs?limit=100", token)
      .then((rows) => { if (current) setEntries(rows); })
      .catch((loadError: unknown) => { if (current) setError(messageFrom(loadError)); })
      .finally(() => { if (current) setLoading(false); });
    return () => { current = false; };
  }, [token, revision, attempt]);

  return (
    <>
      <PageHeading eyebrow="Governance / Activity" title="Audit log" description="A read-only record of administrator changes to markets, schedules and results." action={<span className="audit-retention"><span className="status-indicator status-indicator-live" /> Most recent 100 events</span>} />
      <section className="content-panel">
        <div className="panel-heading"><div><div className="eyebrow">Administrator activity</div><h2>Change history</h2></div><span className="panel-count">{entries.length} events</span></div>
        {loading ? <LoadingState label="Loading audit history" /> : error ? <ErrorState message={error} onRetry={() => setAttempt((value) => value + 1)} /> : entries.length === 0 ? <EmptyState title="No admin activity yet" description="Market, schedule and result changes will be recorded here." /> : (
          <div className="audit-list">
            {entries.map((entry, index) => (
              <article className="audit-entry" key={entry.id}>
                <div className="audit-rail"><span className="audit-node">{index === 0 ? <Check size={13} aria-hidden="true" /> : <span />}</span>{index < entries.length - 1 && <span className="audit-line" />}</div>
                <div className="audit-body">
                  <div className="audit-title-row"><strong>{entry.action.replaceAll(".", " · ")}</strong><time>{formattedDate(entry.created_at, { day: "2-digit", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" })}</time></div>
                  <div className="audit-meta"><span>{entry.resource_type}{entry.resource_id ? ` #${entry.resource_id}` : ""}</span><span>Admin ID {entry.actor_user_id ?? "removed"}</span></div>
                  {entry.details && <details className="audit-details"><summary>View changed fields <ArrowUpRight size={13} aria-hidden="true" /></summary><pre>{JSON.stringify(entry.details, null, 2)}</pre></details>}
                </div>
              </article>
            ))}
          </div>
        )}
      </section>
    </>
  );
}