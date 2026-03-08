import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Users, CreditCard, Activity, DollarSign, Check, X } from 'lucide-react';
import { format } from 'date-fns';

export default function Dashboard() {
    const [kpis, setKpis] = useState({ users: 0, activeSubs: 0, pendingRequests: 0, monthlyRevenue: 0 });
    const [pending, setPending] = useState<any[]>([]);
    const [recentSubs, setRecentSubs] = useState<any[]>([]);

    const loadData = async () => {
        // Users
        const { count: usersCount } = await supabase.from('profiles').select('*', { count: 'exact', head: true });

        // Active Subs
        const { count: activeCount } = await supabase
            .from('subscriptions')
            .select('*', { count: 'exact', head: true })
            .eq('status', 'active')
            .neq('plan_type', 'free');

        // Pending Requests
        const { count: pendingCount, data: pendingData } = await supabase
            .from('payment_requests')
            .select('*, profiles(full_name, shop_name)')
            .eq('status', 'pending')
            .order('submitted_at', { ascending: false });

        // Revenue this month (Rough calculation based on approved payment requests this month)
        const startOfMonth = new Date();
        startOfMonth.setDate(1);
        startOfMonth.setHours(0, 0, 0, 0);

        const { data: revenueData } = await supabase
            .from('payment_requests')
            .select('amount')
            .eq('status', 'approved')
            .gte('reviewed_at', startOfMonth.toISOString());

        const revenue = revenueData?.reduce((acc, curr) => acc + Number(curr.amount), 0) || 0;

        // Recent Subs
        const { data: recentData } = await supabase
            .from('subscriptions')
            .select('*, profiles(full_name)')
            .eq('status', 'active')
            .neq('plan_type', 'free')
            .order('activated_at', { ascending: false })
            .limit(10);

        setKpis({
            users: usersCount || 0,
            activeSubs: activeCount || 0,
            pendingRequests: pendingCount || 0,
            monthlyRevenue: revenue,
        });
        setPending(pendingData || []);
        setRecentSubs(recentData || []);
    };

    useEffect(() => {
        loadData();

        const channel = supabase.channel('dashboard_updates')
            .on('postgres_changes', { event: '*', schema: 'public', table: 'payment_requests' }, () => {
                new Audio('/bell.mp3').play().catch(() => { }); // Optional sound
                loadData();
            })
            .on('postgres_changes', { event: '*', schema: 'public', table: 'subscriptions' }, () => {
                loadData();
            })
            .subscribe();

        return () => {
            supabase.removeChannel(channel);
        };
    }, []);

    const handleActivate = async (id: string, userId: string, planType: string) => {
        try {
            // Need dummy admin ID for service role or omit it if function allows
            const { error } = await supabase.rpc('activate_subscription', {
                p_user_id: userId,
                p_plan: planType,
                p_admin_id: null,
                p_payment_request_id: id
            });
            if (error) throw error;
            loadData();
        } catch (e: any) {
            alert('Error: ' + e.message);
        }
    };

    const handleReject = async (id: string) => {
        const reason = window.prompt('سبب الرفض:');
        if (reason === null) return;

        const { error } = await supabase
            .from('payment_requests')
            .update({ status: 'rejected', rejection_reason: reason, reviewed_at: new Date().toISOString() })
            .eq('id', id);

        if (!error) loadData();
    };

    return (
        <div className="space-y-6">
            <h2 className="text-3xl font-bold">لوحة القيادة</h2>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <KpiCard title="المستخدمين" value={kpis.users} icon={Users} color="text-blue-500" />
                <KpiCard title="مشتركون نشطون" value={kpis.activeSubs} icon={Activity} color="text-success" />
                <KpiCard
                    title="طلبات معلقة"
                    value={kpis.pendingRequests}
                    icon={CreditCard}
                    color={kpis.pendingRequests > 0 ? "text-danger" : "text-gray-400"}
                />
                <KpiCard title="إيرادات الشهر" value={`${kpis.monthlyRevenue.toLocaleString()} د.ع`} icon={DollarSign} color="text-warning" />
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Pending Requests */}
                <div className="bg-surface rounded-xl p-6 border border-gray-800">
                    <h3 className="text-xl font-bold mb-4">الطلبات المعلقة</h3>
                    {pending.length === 0 ? (
                        <p className="text-gray-500 text-center py-4">لا توجد طلبات معلقة حالياً</p>
                    ) : (
                        <div className="space-y-4">
                            {pending.map(req => (
                                <div key={req.id} className="bg-background p-4 rounded-lg flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border border-gray-800">
                                    <div>
                                        <p className="font-bold">{req.profiles?.full_name} <span className="text-gray-400 text-sm">({req.profiles?.shop_name})</span></p>
                                        <p className="text-sm text-gray-400">باقة {req.plan_type === 'yearly' ? 'سنوية' : 'شهرية'} • {req.amount.toLocaleString()} د.ع</p>
                                        <p className="text-xs text-gray-500">{format(new Date(req.submitted_at), 'yyyy-MM-dd HH:mm')}</p>
                                    </div>
                                    <div className="flex gap-2">
                                        <button onClick={() => handleActivate(req.id, req.user_id, req.plan_type)} className="p-2 bg-success/10 text-success rounded hover:bg-success hover:text-white transition-colors">
                                            <Check size={20} />
                                        </button>
                                        <button onClick={() => handleReject(req.id)} className="p-2 bg-danger/10 text-danger rounded hover:bg-danger hover:text-white transition-colors">
                                            <X size={20} />
                                        </button>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                {/* Recent Subscriptions */}
                <div className="bg-surface rounded-xl p-6 border border-gray-800">
                    <h3 className="text-xl font-bold mb-4">آخر الاشتراكات المفعّلة</h3>
                    {recentSubs.length === 0 ? (
                        <p className="text-gray-500 text-center py-4">لا توجد اشتراكات مفعّلة حديثاً</p>
                    ) : (
                        <div className="space-y-4">
                            {recentSubs.map(sub => (
                                <div key={sub.id} className="bg-background p-4 rounded-lg flex justify-between items-center border border-gray-800">
                                    <div>
                                        <p className="font-bold">{sub.profiles?.full_name}</p>
                                        <p className="text-sm text-gray-400">باقة {sub.plan_type === 'yearly' ? 'سنوية' : 'شهرية'}</p>
                                    </div>
                                    <div className="text-left">
                                        <span className="bg-success/20 text-success px-2 py-1 rounded text-xs">نشط</span>
                                        <p className="text-xs text-gray-500 mt-1">{format(new Date(sub.activated_at), 'yyyy-MM-dd')}</p>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}

const KpiCard = ({ title, value, icon: Icon, color }: any) => (
    <div className="bg-surface p-6 rounded-xl border border-gray-800 flex items-center justify-between">
        <div>
            <p className="text-gray-400 text-sm font-medium mb-1">{title}</p>
            <p className={`text-2xl font-bold ${color}`}>{value}</p>
        </div>
        <div className={`p-4 rounded-full bg-background border border-gray-800 ${color}`}>
            <Icon size={24} />
        </div>
    </div>
);
