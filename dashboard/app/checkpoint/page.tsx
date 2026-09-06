import { Suspense } from 'react';
import LinkvertiseWidget from './LinkvertiseWidget';

export const dynamic = 'force-dynamic';

interface CheckpointPageProps {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}

async function CheckpointContent({ searchParams }: CheckpointPageProps) {
  const params = await searchParams;
  const token = typeof params.token === 'string' ? params.token : '';
  const sig = typeof params.sig === 'string' ? params.sig : '';

  if (!token || !sig) {
    return (
      <div style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: '#0a0a0a',
        color: '#fff',
        fontFamily: 'system-ui, sans-serif'
      }}>
        <div style={{ textAlign: 'center', padding: '2rem' }}>
          <h1 style={{ fontSize: '1.5rem', marginBottom: '1rem' }}>Invalid Checkpoint</h1>
          <p style={{ color: '#888' }}>Missing required parameters.</p>
        </div>
      </div>
    );
  }

  const callbackUrl = `https://dashboard-ten-peach-19.vercel.app/api/checkpoint/callback?token=${token}&sig=${sig}`;

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: '#0a0a0a',
      color: '#fff',
      fontFamily: 'system-ui, sans-serif'
    }}>
      <div style={{ textAlign: 'center', padding: '2rem', maxWidth: '500px' }}>
        <h1 style={{ fontSize: '1.5rem', marginBottom: '0.5rem' }}>Speedy Hub Checkpoint</h1>
        <p style={{ color: '#888', marginBottom: '2rem' }}>
          Complete the task below to get your key
        </p>
        <LinkvertiseWidget callbackUrl={callbackUrl} />
      </div>
    </div>
  );
}

export default async function CheckpointPage({ searchParams }: CheckpointPageProps) {
  return (
    <Suspense fallback={
      <div style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: '#0a0a0a',
        color: '#fff',
        fontFamily: 'system-ui, sans-serif'
      }}>
        <p>Loading...</p>
      </div>
    }>
      <CheckpointContent searchParams={searchParams} />
    </Suspense>
  );
}
