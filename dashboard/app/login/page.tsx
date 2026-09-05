"use client";

import { useState, Suspense } from "react";
import { signIn } from "next-auth/react";
import { useSearchParams } from "next/navigation";

function LoginForm() {
  const params = useSearchParams();
  const callbackUrl = params.get("callbackUrl") || "/";
  const [error, setError] = useState("");
  const [pending, setPending] = useState(false);

  async function onSubmit(formData: FormData) {
    setPending(true);
    setError("");
    const res = await signIn("credentials", {
      username: formData.get("username"),
      password: formData.get("password"),
      redirect: false,
      callbackUrl,
    });
    setPending(false);
    if (res?.error) {
      setError("Invalid username or password.");
      return;
    }
    window.location.href = res?.url || callbackUrl;
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-4 bg-[#09090B]">
      <form action={onSubmit} className="panel p-6 md:p-8 w-full max-w-[360px]">
        <div className="flex items-center gap-2.5 mb-6">
          <div className="w-7 h-7 rounded-[8px] bg-[#E5484D] flex items-center justify-center font-bold text-white text-[13px]" style={{ fontFamily: "var(--font-display)" }}>
            S
          </div>
          <div className="leading-none">
            <div className="font-display font-semibold text-[15px] text-[#F4F4F5]">Speedy Hub</div>
            <div className="mono text-[11px] text-[#62626C] mt-1">owner sign in</div>
          </div>
        </div>

        <label className="block mb-3.5">
          <span className="block text-[12.5px] font-medium text-[#A7A7B0] mb-1.5">Username</span>
          <input name="username" autoComplete="username" required className="input" />
        </label>
        <label className="block mb-5">
          <span className="block text-[12.5px] font-medium text-[#A7A7B0] mb-1.5">Password</span>
          <input name="password" type="password" autoComplete="current-password" required className="input" />
        </label>

        {error && (
          <div className="mb-4 text-[13px] text-[#f2555a] border border-red-500/30 bg-red-500/10 rounded-[8px] px-3 py-2">
            {error}
          </div>
        )}

        <button type="submit" disabled={pending} className="btn-primary w-full py-2.5 disabled:opacity-60">
          {pending ? "Signing in…" : "Sign in"}
        </button>
      </form>
    </div>
  );
}

export default function LoginPage() {
  return (
    <Suspense>
      <LoginForm />
    </Suspense>
  );
}
