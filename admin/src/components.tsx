import type { ReactNode } from "react";
import { AlertTriangle, LoaderCircle, RefreshCw } from "lucide-react";

export function PageHeading({
  eyebrow,
  title,
  description,
  action,
}: {
  eyebrow: string;
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <div className="page-heading">
      <div>
        <div className="eyebrow">{eyebrow}</div>
        <h1>{title}</h1>
        <p>{description}</p>
      </div>
      {action && <div className="heading-action">{action}</div>}
    </div>
  );
}

export function LoadingState({ label = "Loading workspace" }: { label?: string }) {
  return (
    <div className="state-panel" role="status">
      <LoaderCircle className="spinner" size={23} aria-hidden="true" />
      <span>{label}</span>
    </div>
  );
}

export function EmptyState({
  title,
  description,
}: {
  title: string;
  description: string;
}) {
  return (
    <div className="empty-state">
      <span className="empty-mark" aria-hidden="true">—</span>
      <h3>{title}</h3>
      <p>{description}</p>
    </div>
  );
}

export function ErrorState({
  message,
  onRetry,
}: {
  message: string;
  onRetry?: () => void;
}) {
  return (
    <div className="error-state" role="alert">
      <AlertTriangle size={20} aria-hidden="true" />
      <div>
        <strong>Could not load this view</strong>
        <p>{message}</p>
      </div>
      {onRetry && (
        <button className="button button-quiet button-small" onClick={onRetry} type="button">
          <RefreshCw size={15} aria-hidden="true" /> Retry
        </button>
      )}
    </div>
  );
}

export function Toast({
  message,
  kind,
  onClose,
}: {
  message: string;
  kind: "success" | "error";
  onClose: () => void;
}) {
  return (
    <div className={`toast toast-${kind}`} role={kind === "error" ? "alert" : "status"}>
      <span className="toast-dot" aria-hidden="true" />
      <span>{message}</span>
      <button className="toast-close" onClick={onClose} type="button" aria-label="Dismiss message">
        ×
      </button>
    </div>
  );
}

export function Modal({
  title,
  description,
  onClose,
  children,
}: {
  title: string;
  description: string;
  onClose: () => void;
  children: ReactNode;
}) {
  return (
    <div className="modal-backdrop" role="presentation" onMouseDown={(event) => {
      if (event.target === event.currentTarget) onClose();
    }}>
      <section className="modal" role="dialog" aria-modal="true" aria-labelledby="modal-title">
        <div className="modal-heading">
          <div>
            <div className="eyebrow">Workspace action</div>
            <h2 id="modal-title">{title}</h2>
            <p>{description}</p>
          </div>
          <button className="icon-button modal-close" onClick={onClose} type="button" aria-label="Close dialog">
            ×
          </button>
        </div>
        {children}
      </section>
    </div>
  );
}

export function StatusBadge({ active }: { active: boolean }) {
  return (
    <span className={`status-badge ${active ? "status-active" : "status-inactive"}`}>
      <span className="status-indicator" />
      {active ? "Active" : "Paused"}
    </span>
  );
}

export function TableEmpty({ columns, message }: { columns: number; message: string }) {
  return (
    <tr>
      <td colSpan={columns} className="table-empty">{message}</td>
    </tr>
  );
}