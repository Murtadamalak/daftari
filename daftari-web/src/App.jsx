import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import { Home as HomeIcon, Users, Package, FileText, Settings } from 'lucide-react';
import Home from './pages/Home';

function App() {
    return (
        <Router>
            <div className="app-container">
                {/* Sidebar */}
                <aside className="sidebar">
                    <div style={{ marginBottom: '2rem', textAlign: 'center' }}>
                        <h2>دفتري</h2>
                        <p style={{ color: 'var(--text-muted)' }}>إدارة أعمالك بذكاء</p>
                    </div>

                    <nav style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                        <Link to="/" style={linkStyle}><HomeIcon size={20} /> الرئيسية</Link>
                        <Link to="/invoices" style={linkStyle}><FileText size={20} /> الفواتير</Link>
                        <Link to="/products" style={linkStyle}><Package size={20} /> المنتجات</Link>
                        <Link to="/customers" style={linkStyle}><Users size={20} /> العملاء</Link>
                        <Link to="/settings" style={linkStyle}><Settings size={20} /> الإعدادات</Link>
                    </nav>
                </aside>

                {/* content */}
                <main className="main-content">
                    <Routes>
                        <Route path="/" element={<Home />} />
                        <Route path="/invoices" element={<h1>إدارة الفواتير</h1>} />
                        <Route path="/products" element={<h1>إدارة المنتجات</h1>} />
                        <Route path="/customers" element={<h1>إدارة العملاء</h1>} />
                        <Route path="/settings" element={<h1>الإعدادات</h1>} />
                    </Routes>
                </main>
            </div>
        </Router>
    );
}

const linkStyle = {
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    padding: '12px 16px',
    textDecoration: 'none',
    color: 'var(--text-main)',
    borderRadius: '8px',
    transition: 'background 0.2s',
    fontWeight: '600'
};

export default App;
