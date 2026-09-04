import Link from "next/link";

export default function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] text-center">
      <div className="mono text-[13px] text-[#62626C]">404</div>
      <h2 className="font-display font-semibold text-[22px] text-[#F4F4F5] mt-2">Page not found</h2>
      <p className="text-[13.5px] text-[#A7A7B0] mt-2 mb-6 max-w-xs">
        This page does not exist or was moved. The old API Keys page was removed.
      </p>
      <Link href="/" className="btn-ghost px-5 py-2.5">
        Back to overview
      </Link>
    </div>
  );
}
