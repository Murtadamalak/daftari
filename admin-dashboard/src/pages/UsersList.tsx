import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Search, Filter, MoreVertical, X } from 'lucide-react';
import { format } from 'date-fns';

export default function UsersList() {
    const [users, setUsers] = useState<any[]>([]);
    const [search, setSearch] = useState('');
    const [filter, setFilter] = useState('all'); // all, active, expired, free, pending
    const [selectedUser, setSelectedUser] = useState<any | null>(null);
    const [userHistory, setUserHistory] = useState<any[]>([]);

    const fetchUsers = async () => {
        let query = supabase.from('profiles').select(`
      *,
      subscriptions (*),
      payment_requests (status)
    `);

        // Using client-side filtering for simplicity and responsiveness with complex conditions
        const { data } = await query;
        setUsers(data || []);
    };

    useEffect(() => {
        fetchUsers();
    }, []);

    const filteredUsers = users.filter((u) => {
        const term = search.toLowerCase();
        const matchSearch =
            (u.full_name || '').toLowerCase().includes(term) ||
            (u.phone || '').includes(term) ||
            (u.shop_name || '').toLowerCase().includes(term);

        const sub = u.subscriptions?.[0]; // Assuming 1 active sub per user
        const hasPending = u.payment_requests?.some((r: any) => r.status === 'pending');

        let matchFilter = true;
        if (filter === 'active') matchFilter = sub?.status === 'active' && sub?.plan_type !== 'free';
        if (filter === 'free') matchFilter = sub?.plan_type === 'free';
        if (filter === 'expired') matchFilter = sub?.status === 'expired';
        if (filter === 'pending') matchFilter = hasPending;

        return matchSearch && matchFilter;
    });

    const openDrawer = async (user: any) => {
        setSelectedUser(user);
        // Fetch History
        const { data } = await supabase
            .from('payment_requests')
            .select('*')
            .eq('user_id', user.id)
            .order('submitted_at', { ascending: false });
        setUserHistory(data || []);
    };

    const handleManualAction = async (plan: string, userId: string, isUpdate = false) => {
        try {
            const { error } = await supabase.rpc('activate_subscription', {
                p_user_id: userId,
                p_plan: plan,
                p_admin_id: null,
            });
            if (error) throw error;
            alert('تم التنفيذ بنجاح!');
            fetchUsers();
            setSelectedUser(null);
        } catch (e: any) {
            alert('خطأ: ' + e.message);
        }
    };

    const stopSubscription = async (userId: string) => {
        if (!confirm('تأكيد إيقاف اشتراك هذا المستخدم وجعله منتهي؟')) return;
        try {
            const { error } = await supabase
                .from('subscriptions')
                .update({ status: 'expired', end_date: new Date().toISOString() })
                .eq('user_id', userId);
            if (error) throw error;
            alert('تم التنفيذ بنجاح!');
            fetchUsers();
            setSelectedUser(null);
        } catch (e: any) {
            alert('خطأ: ' + e.message);
        }
    };

    return (
        <div className="space-y-6 flex h-full flex-col relative">
            <h2 className="text-3xl font-bold mb-6">المستخدمين</h2>

            <div className="flex flex-col md:flex-row gap-4 justify-between items-center mb-6">
                <div className="relative w-full md:w-1/3">
                    <input
                        type="text"
                        placeholder="بحث بالاسم، المحل، الهاتف..."
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        className="w-full bg-surface border border-gray-700 rounded-lg px-4 py-3 pl-10 text-white focus:outline-none focus:border-primary"
                    />
                    <Search className="absolute left-3 top-3 text-gray-400" size={20} />
                </div>

                <div className="flex gap-2 w-full md:w-auto overflow-x-auto pb-2">
                    {['all', 'active', 'free', 'expired', 'pending'].map(f => (
                        <button
                            key={f}
                            onClick={() => setFilter(f)}
                            className={`px-4 py-2 rounded-lg whitespace-nowrap transition-colors ${filter === f ? 'bg-primary text-white font-bold' : 'bg-surface text-gray-400 hover:bg-gray-800'}`}
                        >
                            {f === 'all' && 'الكل'}
                            {f === 'active' && 'نشط'}
                            {f === 'free' && 'مجانى'}
                            {f === 'expired' && 'منتهي'}
                            {f === 'pending' && 'معلّق'}
                        </button>
                    ))}
                </div>
            </div>

            <div className="bg-surface rounded-xl border border-gray-800 flex-1 overflow-auto">
                <table className="w-full text-left" dir="rtl">
                    <thead className="bg-gray-800 text-gray-400 sticky top-0">
                        <tr>
                            <th className="p-4 rounded-tr-xl">المستخدم والمحل</th>
                            <th className="p-4">الهاتف</th>
                            <th className="p-4">نوع الاشتراك</th>
                            <th className="p-4">الحالة</th>
                            <th className="p-4">تاريخ الانتهاء</th>
                            <th className="p-4 rounded-tl-xl text-center">التفاصيل</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-800">
                        {filteredUsers.length === 0 && (
                            <tr>
                                <td colSpan={6} className="p-8 text-center text-gray-500">
                                    لا يوجد مستخدمين مطابقيين
                                </td>
                            </tr>
                        )}
                        {filteredUsers.map(user => {
                            const sub = user.subscriptions?.[0] || { plan_type: 'free', status: 'active' };
                            const hasPending = user.payment_requests?.some((r: any) => r.status === 'pending');
                            const isExpired = sub.status === 'expired' || (sub.end_date && new Date(sub.end_date) < new Date());

                            return (
                                <tr key={user.id} className="hover:bg-gray-800/50 transition-colors cursor-pointer" onClick={() => openDrawer(user)}>
                                    <td className="p-4">
                                        <div className="font-bold text-white">{user.full_name}</div>
                                        <div className="text-sm text-gray-500">{user.shop_name}</div>
                                    </td>
                                    <td className="p-4" dir="ltr">{user.phone}</td>
                                    <td className="p-4">
                                        <span className="px-2 py-1 bg-gray-800 rounded text-xs">
                                            {sub.plan_type === 'yearly' ? 'سنوي' : sub.plan_type === 'monthly' ? 'شهري' : 'مجاني'}
                                        </span>
                                    </td>
                                    <td className="p-4">
                                        {hasPending ? (
                                            <span className="text-warning font-bold text-sm">معلّق</span>
                                        ) : isExpired ? (
                                            <span className="text-danger font-bold text-sm">منتهي</span>
                                        ) : (
                                            <span className="text-success font-bold text-sm">نشط</span>
                                        )}
                                    </td>
                                    <td className="p-4 text-sm text-gray-400">
                                        {sub.end_date ? format(new Date(sub.end_date), 'yyyy-MM-dd') : 'غير محدود'}
                                    </td>
                                    <td className="p-4 text-center">
                                        <button className="p-2 text-gray-400 hover:text-white transition-colors">
                                            <MoreVertical size={20} />
                                        </button>
                                    </td>
                                </tr>
                            )
                        })}
                    </tbody>
                </table>
            </div>

            {/* Drawer */}
            {selectedUser && (
                <>
                    <div className="fixed inset-0 bg-black/60 z-40 transition-opacity" onClick={() => setSelectedUser(null)} />
                    <div className="fixed top-0 bottom-0 left-0 w-96 max-w-full bg-surface shadow-2xl z-50 transform transition-transform border-r border-gray-800 flex flex-col overflow-hidden">
                        <div className="p-6 border-b border-gray-800 flex justify-between items-center bg-background">
                            <h3 className="text-2xl font-bold">تفاصيل المستخدم</h3>
                            <button onClick={() => setSelectedUser(null)} className="text-gray-400 hover:text-white">
                                <X size={24} />
                            </button>
                        </div>

                        <div className="p-6 flex-1 overflow-auto space-y-6">
                            <div>
                                <p className="text-sm text-gray-400">الاسم والمحل</p>
                                <p className="text-xl font-bold">{selectedUser.full_name}</p>
                                <p className="text-gray-300">{selectedUser.shop_name}</p>
                            </div>

                            <div className="bg-background p-4 rounded-xl border border-gray-800 space-y-3">
                                <p className="text-sm font-bold text-primary mb-2">الاشتراك الحالي</p>
                                <div className="flex justify-between items-center">
                                    <span className="text-gray-400">الباقة</span>
                                    <span className="font-bold">{selectedUser.subscriptions?.[0]?.plan_type}</span>
                                </div>
                                <div className="flex justify-between items-center">
                                    <span className="text-gray-400">تاريخ الانتهاء</span>
                                    <span className="font-bold">{selectedUser.subscriptions?.[0]?.end_date ? format(new Date(selectedUser.subscriptions[0].end_date), 'yyyy-MM-dd') : 'N/A'}</span>
                                </div>
                            </div>

                            <div className="space-y-3">
                                <p className="text-sm font-bold text-gray-400">إجراءات إدارية مستعجلة</p>
                                <div className="grid grid-cols-2 gap-3">
                                    <button onClick={() => handleManualAction('monthly', selectedUser.id)} className="bg-primary/20 hover:bg-primary/30 text-primary p-3 rounded-lg font-bold text-sm transition-colors text-center border border-primary/30">
                                        تفعيل شهر
                                    </button>
                                    <button onClick={() => handleManualAction('yearly', selectedUser.id)} className="bg-warning/20 hover:bg-warning/30 text-warning p-3 rounded-lg font-bold text-sm transition-colors text-center border border-warning/30">
                                        تفعيل سنة
                                    </button>
                                    <button onClick={() => stopSubscription(selectedUser.id)} className="col-span-2 bg-danger/10 hover:bg-danger/20 text-danger p-3 rounded-lg font-bold text-sm transition-colors text-center border border-danger/30">
                                        إيقاف الاشتراك
                                    </button>
                                </div>
                            </div>

                            <div>
                                <p className="text-sm font-bold text-gray-400 mb-3">سجل الدفعات</p>
                                {userHistory.length === 0 ? (
                                    <p className="text-sm text-gray-500">لا توجد دفوعات مسجلة</p>
                                ) : (
                                    <div className="space-y-3">
                                        {userHistory.map(history => (
                                            <div key={history.id} className="bg-background p-3 rounded-lg border border-gray-800 text-sm">
                                                <div className="flex justify-between font-bold mb-1">
                                                    <span>{history.plan_type} • {history.amount} د.ع</span>
                                                    <span className={`${history.status === 'approved' ? 'text-success' : history.status === 'rejected' ? 'text-danger' : 'text-warning'}`}>{history.status}</span>
                                                </div>
                                                <p className="text-gray-500 text-xs">{format(new Date(history.submitted_at), 'yyyy-MM-dd HH:mm')}</p>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                </>
            )}
        </div>
    );
}
