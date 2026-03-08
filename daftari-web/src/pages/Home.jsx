import { useEffect, useState } from 'react';
import { supabase } from '../supabase/client';

export default function Home() {
    const [stats, setStats] = useState({ products: 0, customers: 0, invoices: 0 });
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function fetchStats() {
            // Assuming user is logged in. In a full app we check session first.
            const session = await supabase.auth.getSession();

            const [productsRes, customersRes, invoicesRes] = await Promise.all([
                supabase.from('user_products').select('*', { count: 'exact', head: true }),
                supabase.from('user_customers').select('*', { count: 'exact', head: true }),
                supabase.from('user_invoices').select('*', { count: 'exact', head: true })
            ]);

            setStats({
                products: productsRes.count || 0,
                customers: customersRes.count || 0,
                invoices: invoicesRes.count || 0
            });
            setLoading(false);
        }
        fetchStats();
    }, []);

    if (loading) return <div>جاري التحميل...</div>;

    return (
        <div>
            <h1 style={{ marginBottom: '2rem' }}>لوحة التحكم</h1>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '1.5rem' }}>
                <div style={cardStyle}>
                    <h3>إجمالي المنتجات</h3>
                    <h2 style={{ color: 'var(--primary)', fontSize: '2rem' }}>{stats.products}</h2>
                </div>
                <div style={cardStyle}>
                    <h3>إجمالي العملاء</h3>
                    <h2 style={{ color: 'var(--secondary)', fontSize: '2rem' }}>{stats.customers}</h2>
                </div>
                <div style={cardStyle}>
                    <h3>إجمالي الفواتير</h3>
                    <h2 style={{ color: 'var(--danger)', fontSize: '2rem' }}>{stats.invoices}</h2>
                </div>
            </div>
        </div>
    );
}

const cardStyle = {
    backgroundColor: 'var(--surface)',
    padding: '1.5rem',
    borderRadius: '12px',
    boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
    display: 'flex',
    flexDirection: 'column',
    gap: '0.5rem'
};
