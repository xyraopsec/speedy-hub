import Link from "next/link";

export default function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] text-center">
      <div className="text-8xl font-black tracking-tighter text-white/10 mb-4">404</div>
      <h2 className="text-xl font-bold text-white/70 mb-2">Page not found</h2>
      <p className="text-sm text-white/40 mb-8 max-w-xs">
        The page you are looking for does not exist or has been moved.
      </p>
      <Link
        href="/"
        className="bg-white text-black font-bold px-6 py-3 rounded-lg text-sm hover:bg-white/90 transition-colors"
      >
        Back to Dashboard
      </Link>
    </div>
  );
}
