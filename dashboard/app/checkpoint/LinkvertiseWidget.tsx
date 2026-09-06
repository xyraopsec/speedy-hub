'use client';

import { useEffect, useRef, useState } from 'react';

declare global {
  interface Window {
    linkvertise?: (userId: number, options: { whitelist: string[], blacklist: string[] }) => void;
  }
}

interface LinkvertiseWidgetProps {
  callbackUrl: string;
}

export default function LinkvertiseWidget({ callbackUrl }: LinkvertiseWidgetProps) {
  const linkRef = useRef<HTMLAnchorElement>(null);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    // Load the Linkvertise script
    const script = document.createElement('script');
    script.src = 'https://publisher.linkvertise.com/cdn/linkvertise.js';
    script.async = true;
    script.onload = () => {
      // Initialize Linkvertise after script loads
      if (window.linkvertise) {
        window.linkvertise(9061250, {
          whitelist: [],
          blacklist: ['speedy-keys-eight.vercel.app', 'dashboard-ten-peach-19.vercel.app']
        });
        setLoaded(true);
      }
    };
    document.head.appendChild(script);

    return () => {
      // Cleanup
      if (script.parentNode) {
        script.parentNode.removeChild(script);
      }
    };
  }, []);

  return (
    <div>
      {!loaded && (
        <p style={{ color: '#888', marginBottom: '1rem' }}>Loading checkpoint...</p>
      )}
      <a
        ref={linkRef}
        href={callbackUrl}
        id="linkvertise-link"
        style={{
          display: 'inline-block',
          padding: '12px 24px',
          background: '#2563eb',
          color: '#fff',
          textDecoration: 'none',
          borderRadius: '8px',
          fontSize: '1rem',
          fontWeight: '600',
          transition: 'background 0.2s',
          cursor: loaded ? 'pointer' : 'not-allowed',
          opacity: loaded ? 1 : 0.5
        }}
        onMouseOver={(e) => {
          if (loaded) e.currentTarget.style.background = '#1d4ed8';
        }}
        onMouseOut={(e) => {
          if (loaded) e.currentTarget.style.background = '#2563eb';
        }}
      >
        Get Your Key
      </a>
    </div>
  );
}
