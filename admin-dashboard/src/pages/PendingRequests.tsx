import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Check, X, Eye } from 'lucide-react';
import { format } from 'date-fns';

export default function PendingRequests() {
    const [requests, setRequests] = useState<any[]>([]);
    const [selectedReceipt, setSelectedReceipt] = useState<string | null>(null);

    const fetchRequests = async () => {
        const { data } = await supabase
            .from('payment_requests')
            .select('*, profiles(full_name, shop_name, phone)')
            .eq('status', 'pending')
            .order('submitted_at', { ascending: false });

        setRequests(data || []);
    };

    useEffect(() => {
        fetchRequests();
        const channel = supabase.channel('pending_updates')
            .on('postgres_changes', { event: '*', schema: 'public', table: 'payment_requests', filter: 'status=eq.pending' }, (payload) => {
                new Audio('/bell.mp3').play().catch(() => { });
                fetchRequests();
            })
            .subscribe();

        return () => { supabase.removeChannel(channel); };
    }, []);

    const handleActivate = async (req: any) => {
        if (!window.confirm(`هل تريد تفعيل اشتراك ${req.profiles?.full_name} لمدة ${req.plan_type === 'yearly' ? 'سنة' : 'شهر'}؟`)) return;

        try {
            const { error } = await supabase.rpc('activate_subscription', {
                p_user_id: req.user_id,
                p_plan: req.plan_type,
                p_admin_id: null,
                p_payment_request_id: req.id
            });
            if (error) throw error;
            fetchRequests(); // Optimistic update can also be used here
        } catch (e: any) {
            alert('خطأ في التفعيل: ' + e.message);
        }
    };

    const handleReject = async (reqId: string) => {
        const reason = window.prompt("ادخل سبب الرفض:");
        if (reason === null) return; // User cancelled

        try {
            const { error } = await supabase
                .from('payment_requests')
                .update({ status: 'rejected', rejection_reason: reason, reviewed_at: new Date().toISOString() })
                .eq('id', reqId);
            if (error) throw error;
            fetchRequests();
        } catch (e: any) {
            alert('خطأ في الرفض: ' + e.message);
        }
    };

    return (
        <div className="space-y-6">
            <h2 className="text-3xl font-bold">الطلبات المعلقة</h2>

            <div className="bg-surface rounded-xl border border-gray-800 overflow-hidden">
                <div className="overflow-x-auto">
                    <table className="w-full text-left" dir="rtl">
                        <thead className="bg-gray-800 text-gray-400">
                            <tr>
                                <th className="p-4 rounded-tr-xl">رقم الطلب</th>
                                <th className="p-4">المستخدم / المحل</th>
                                <th className="p-4">رقم الهاتف</th>
                                <th className="p-4">الباقة المطلوبة</th>
                                <th className="p-4">المبلغ</th>
                                <th className="p-4">رقم العملية</th>
                                <th className="p-4">وقت الإرسال</th>
                                <th className="p-4">الإيصال</th>
                                <th className="p-4 rounded-tl-xl text-center">إجراءات</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-800">
                            {requests.length === 0 && (
                                <tr>
                                    <td colSpan={9} className="p-8 text-center text-gray-500">
                                        لا توجد طلبات معلقة
                                    </td>
                                </tr>
                            )}
                            {requests.map(req => (
                                <tr key={req.id} className="hover:bg-gray-800/50 transition-colors animate-fade-in">
                                    <td className="p-4 text-sm font-mono text-gray-400">...{req.id.slice(-6)}</td>
                                    <td className="p-4">
                                        <div className="font-bold text-white">{req.profiles?.full_name}</div>
                                        <div className="text-sm text-gray-500">{req.profiles?.shop_name}</div>
                                    </td>
                                    <td className="p-4" dir="ltr">{req.profiles?.phone}</td>
                                    <td className="p-4">
                                        <span className={`px-2 py-1 rounded text-xs font-bold ${req.plan_type === 'yearly' ? 'bg-warning/20 text-warning' : 'bg-primary/20 text-primary'}`}>
                                            {req.plan_type === 'yearly' ? 'سنوي' : 'شهري'}
                                        </span>
                                    </td>
                                    <td className="p-4 text-success font-bold">{req.amount.toLocaleString()} د.ع</td>
                                    <td className="p-4 text-sm text-gray-400 font-mono" dir="ltr">{req.transfer_number || 'غير متوفر'}</td>
                                    <td className="p-4 text-sm text-gray-400">
                                        {format(new Date(req.submitted_at), 'yyyy-MM-dd HH:mm')}
                                    </td>
                                    <td className="p-4">
                                        <button
                                            onClick={() => setSelectedReceipt(req.receipt_url)}
                                            className="p-2 bg-blue-500/10 text-blue-500 rounded hover:bg-blue-500 hover:text-white transition-colors"
                                            title="عرض الإيصال"
                                        >
                                            <Eye size={18} />
                                        </button>
                                    </td>
                                    <td className="p-4">
                                        <div className="flex gap-2 justify-center">
                                            <button
                                                onClick={() => handleActivate(req)}
                                                className="p-2 bg-success/10 text-success rounded hover:bg-success hover:text-white transition-colors"
                                                title="تفعيل"
                                            >
                                                <Check size={18} />
                                            </button>
                                            <button
                                                onClick={() => handleReject(req.id)}
                                                className="p-2 bg-danger/10 text-danger rounded hover:bg-danger hover:text-white transition-colors"
                                                title="رفض"
                                            >
                                                <X size={18} />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>

            {selectedReceipt && (
                <div className="fixed inset-0 bg-black/80 flex items-center justify-center p-4 z-50 animate-fade-in" onClick={() => setSelectedReceipt(null)}>
                    <div className="bg-surface p-4 rounded-xl max-w-3xl max-h-[90vh] overflow-auto relative" onClick={e => e.stopPropagation()}>
                        <button
                            className="absolute top-2 right-2 p-2 bg-black/50 text-white rounded-full hover:bg-black"
                            onClick={() => setSelectedReceipt(null)}
                        >
                            <X size={20} />
                        </button>
                        <img src={selectedReceipt} alt="الإيصال" className="w-full h-auto rounded-lg" />
                    </div>
                </div>
            )}
        </div>
    );
}
