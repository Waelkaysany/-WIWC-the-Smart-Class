import React, { useEffect, useState } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { ref, update, remove, get } from 'firebase/database';
import { db } from '../services/firebase';

const ApproveUser = () => {
  const [searchParams] = useSearchParams();
  const [status, setStatus] = useState('processing'); // processing, success, error
  const uid = searchParams.get('uid');
  const navigate = useNavigate();

  useEffect(() => {
    const performApproval = async () => {
      if (!uid) {
        setStatus('error');
        return;
      }

      try {
        // 1. Update user profile
        const userRef = ref(db, `users/${uid}`);
        const snapshot = await get(userRef);

        if (!snapshot.exists()) {
          setStatus('error');
          return;
        }

        await update(userRef, { isApproved: true });

        // 2. Remove from pending approvals
        await remove(ref(db, `pending_approvals/${uid}`));

        setStatus('success');

        // Optional: Auto-redirect to dashboard after 3 seconds
        setTimeout(() => navigate('/'), 3000);
      } catch (error) {
        console.error("Approval failed:", error);
        setStatus('error');
      }
    };

    performApproval();
  }, [uid, navigate]);

  return (
    <div className="min-h-screen bg-[#050505] flex items-center justify-center p-4">
      <div className="max-w-md w-full glass p-8 rounded-3xl border border-white/10 text-center animate-in fade-in zoom-in duration-500">
        {status === 'processing' && (
          <div className="flex flex-col items-center">
            <div className="w-12 h-12 border-4 border-indigo-500/30 border-t-indigo-500 rounded-full animate-spin mb-6"></div>
            <h2 className="text-2xl font-bold text-white mb-2">Processing Approval</h2>
            <p className="text-gray-400">Verifying teacher credentials...</p>
          </div>
        )}

        {status === 'success' && (
          <div className="flex flex-col items-center">
            <div className="w-20 h-20 bg-emerald-500/20 rounded-full flex items-center justify-center mb-6">
              <svg className="w-10 h-10 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M5 13l4 4L19 7"></path>
              </svg>
            </div>
            <h2 className="text-2xl font-bold text-white mb-2">Teacher Approved!</h2>
            <p className="text-gray-400 mb-6">They now have full access to the WIWC Smart Classroom. Redirecting you to dashboard...</p>
            <button
              onClick={() => navigate('/')}
              className="px-6 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl transition-all"
            >
              Go to Dashboard
            </button>
          </div>
        )}

        {status === 'error' && (
          <div className="flex flex-col items-center">
            <div className="w-20 h-20 bg-red-500/20 rounded-full flex items-center justify-center mb-6">
              <svg className="w-10 h-10 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M6 18L18 6M6 6l12 12"></path>
              </svg>
            </div>
            <h2 className="text-2xl font-bold text-white mb-2">Approval Failed</h2>
            <p className="text-gray-400 mb-6">We couldn't process this request. The link may be invalid or expired.</p>
            <button
              onClick={() => navigate('/')}
              className="px-6 py-2 bg-white/10 hover:bg-white/20 text-white rounded-xl transition-all"
            >
              Return to Safety
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default ApproveUser;
