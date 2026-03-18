import { useState, useEffect } from 'react';
import './index.css';

function App() {
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState(null);
  const [statusType, setStatusType] = useState(''); // 'error', 'success', 'loading'
  const [userId, setUserId] = useState(null);
  const [returnUrl, setReturnUrl] = useState(null);
  const [tier, setTier] = useState('premium'); // 'premium' or 'reporter'
  const [isDarkMode, setIsDarkMode] = useState(window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches);

  useEffect(() => {
    // Theme listener
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    const handler = (e) => setIsDarkMode(e.matches);
    mediaQuery.addEventListener('change', handler);

    const params = new URLSearchParams(window.location.search);
    const id = params.get('userId');
    const ret = params.get('return_url');
    const tierParam = params.get('tier');

    if (tierParam === 'premium' || tierParam === 'reporter') {
      setTier(tierParam);
    }

    if (id) setUserId(id);
    if (ret) setReturnUrl(ret);

    if (!id) {
      setStatus('Session error: Missing User ID. Please restart the upgrade flow from the Tracks app.');
      setStatusType('error');
    }

    return () => mediaQuery.removeEventListener('change', handler);
  }, []);

  const handlePayment = () => {
    if (!userId) return;

    setLoading(true);
    setStatus('Connecting to secure gateway...');
    setStatusType('loading');

    if (!window.webpayCheckout) {
      setStatus('Gateway error: Security script failed to load.');
      setStatusType('error');
      setLoading(false);
      return;
    }

    const txnRef = "TRKS-" + Date.now() + Math.floor(Math.random() * 1000);

    const paymentRequest = {
      merchant_code: "MX6072",
      pay_item_id: "9405967",
      txn_ref: txnRef,
      amount: tier === 'reporter' ? "700000" : "300000",
      currency: 566,
      site_redirect_url: window.location.href,
      mode: "TEST",
      onComplete: paymentCallback
    };

    window.webpayCheckout(paymentRequest);
  };

  const paymentCallback = async (response) => {
    setLoading(false);

    if (response && (response.responseCode === "00" || response.desc === "Approved by Financial Institution" || response.resp === "00")) {
      setStatus('Verifying transaction with Tracks Cloud...');
      setStatusType('loading');

      try {
        const verifyReq = await fetch(`https://traks-api-945904604038.us-central1.run.app/users/${userId}/verify`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            reporter: "True",
            isReporter: tier === 'reporter'
          })
        });

        if (!verifyReq.ok) throw new Error("Verification failed.");

        setStatus('Upgrade complete! Redirecting you back...');
        setStatusType('success');

        const redirectUri = returnUrl
          ? `${returnUrl}?status=success&userId=${userId}`
          : `traksapp://payment?status=success&userId=${userId}`;

        setTimeout(() => {
          window.location.href = redirectUri;
        }, 2000);

      } catch (err) {
        setStatus('Payment successful, but verification timed out. Your account will be updated shortly.');
        setStatusType('error');
      }
    } else {
      setStatus('Transaction cancelled or declined. Please try again.');
      setStatusType('error');
    }
  };

  return (
    <div className={`app-container ${isDarkMode ? 'theme-dark' : 'theme-light'}`}>
      <div className="payment-card">
        <div className="logo-section">
          <img 
            src={isDarkMode ? "/logo-light.png" : "/logo-dark.png"} 
            alt="Tracks Logo" 
            className="app-logo" 
          />
        </div>

        <div className="header-section">
          <div className="tier-badge">
            {tier === 'reporter' ? 'Professional' : 'Personal'}
          </div>
          <h1 className="title">
            {tier === 'reporter' ? 'Reporter Pro' : 'Tracks Premium'}
          </h1>
          <p className="subtitle">
            {tier === 'reporter' 
              ? 'Unlock advanced investigation tools and official reporter status.' 
              : 'Enhance your safety experience with verified features and zero ads.'}
          </p>
        </div>

        <div className="amount-section">
          <div className="amount-label">Membership Fee</div>
          <div className="amount-value">
            <span className="currency">₦</span>
            {tier === 'reporter' ? '7,000' : '3,000'}
          </div>
        </div>

        <button
          className="primary-button"
          onClick={handlePayment}
          disabled={loading || !userId}
        >
          {loading ? (
            <>
              <div className="spinner"></div> Authorizing...
            </>
          ) : (
            "Complete Payment"
          )}
        </button>

        {status && (
          <div className={`status-message status-${statusType}`}>
            {status}
          </div>
        )}

        <div className="security-footer">
          <svg fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
            <path fillRule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clipRule="evenodd"></path>
          </svg>
          256-bit Secure Encryption
        </div>
      </div>
    </div>
  );
}

export default App;
