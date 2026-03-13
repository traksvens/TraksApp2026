import { useState, useEffect } from 'react';
import './index.css';

function App() {
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState(null);
  const [statusType, setStatusType] = useState(''); // 'error', 'success', 'loading'
  const [userId, setUserId] = useState(null);
  const [returnUrl, setReturnUrl] = useState(null);
  const [tier, setTier] = useState('premium'); // 'premium' or 'reporter'

  useEffect(() => {
    // Parse URL parameters
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
      setStatus('Error: Missing User ID. Please restart the verification flow from the app.');
      setStatusType('error');
    }
  }, []);

  const handlePayment = () => {
    if (!userId) return;

    setLoading(true);
    setStatus('Initializing secure gateway...');
    setStatusType('loading');

    // Make sure the Interswitch JS is loaded
    if (!window.webpayCheckout) {
      setStatus('Gateway script failed to load. Please check your connection.');
      setStatusType('error');
      setLoading(false);
      return;
    }

    const txnRef = "MX-TRN-" + Math.floor(Math.random() * 1000000);

    const paymentRequest = {
      merchant_code: "MX6072",
      pay_item_id: "9405967",
      txn_ref: txnRef,
      amount: tier === 'reporter' ? "700000" : "300000", // Kobo
      currency: 566, // NGN
      site_redirect_url: window.location.href, // Safe redirect
      mode: "TEST",
      onComplete: paymentCallback
    };

    // Open the modal
    window.webpayCheckout(paymentRequest);
  };

  const paymentCallback = async (response) => {
    console.log("Interswitch Response:", response);
    setLoading(false);

    // In our insecure test validation as per demo instructions:
    if (response && (response.responseCode === "00" || response.desc === "Approved by Financial Institution" || response.resp === "00")) {
      setStatus('Authorizing Transaction with Core API...');
      setStatusType('loading');

      try {
        const verifyReq = await fetch(`https://traks-api-945904604038.us-central1.run.app/users/${userId}/verify`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            verified: "True",
            reporter: tier === 'reporter' ? "True" : "False"
          })
        });

        if (!verifyReq.ok) {
          throw new Error("API verification failed.");
        }

        setStatus('Payment Verified Successfully! Redirecting you back to the app...');
        setStatusType('success');

        // Determine the redirect URI
        // Defaulting to the custom scheme if no return_url was provided
        const redirectUri = returnUrl
          ? `${returnUrl}?status=success&userId=${userId}`
          : `traksapp://payment?status=success&userId=${userId}`;

        // Execute Redirection after providing a brief visual delay to read the success message
        setTimeout(() => {
          window.location.href = redirectUri;
        }, 2000);

      } catch (err) {
        console.error("Verification Error:", err);
        setStatus('Payment succeeded, but backend verification failed. Please contact support.');
        setStatusType('error');
      }

    } else {
      setStatus('Payment was cancelled or failed. Please try again.');
      setStatusType('error');
    }
  };

  return (
    <div className="app-container">
      <div className="payment-card">
        <div className="header-section">
          <div className="tier-icon">
            {tier === 'reporter' ? (
              <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M12 20h9"></path>
                <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"></path>
              </svg>
            ) : (
              <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
              </svg>
            )}
          </div>
          <h1 className="title">{tier === 'reporter' ? 'Reporter Tier' : 'Premium Tier'}</h1>
          <p className="subtitle">{tier === 'reporter' ? 'Unlock full reporting and investigative capabilities.' : 'Securely verify your account to unlock premium features.'}</p>
        </div>

        <div className="amount-display">
          <div className="amount-label">Amount Due</div>
          <div className="amount-value">
            <span className="currency">₦</span>{tier === 'reporter' ? '7,000.00' : '3,000.00'}
          </div>
        </div>

        <button
          className="primary-button"
          onClick={handlePayment}
          disabled={loading || !userId}
        >
          {loading ? (
            <>
              <div className="spinner"></div> Processing...
            </>
          ) : (
            "Pay Securely"
          )}
        </button>

        {status && (
          <div className={`status-message status-${statusType}`}>
            {status}
          </div>
        )}

        <div className="security-badge">
          <svg fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
            <path fillRule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clipRule="evenodd"></path>
          </svg>
          Secured by Interswitch Webpay
        </div>
      </div>
    </div>
  );
}

export default App;
