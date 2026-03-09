import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Save } from 'lucide-react';

export default function Settings() {
    const [loading, setLoading] = useState(true);
    const [config, setConfig] = useState({
        payment_info: { zain_cash_number: '', account_holder: '' },
        pricing: { monthly: 10000, yearly: 99000 },
        welcome_message: { title: '', body: '' },
        support: { whatsapp: '' }
    });

    useEffect(() => {
        const fetchConfig = async () => {
            const { data } = await supabase.from('app_config').select('*');
            if (data) {
                const newConfig = { ...config };
                data.forEach((row) => {
                    if (row.key === 'payment_info') newConfig.payment_info = row.value;
                    if (row.key === 'pricing') newConfig.pricing = row.value;
                    if (row.key === 'welcome_message') newConfig.welcome_message = row.value;
                    if (row.key === 'support') newConfig.support = row.value;
                });
                setConfig(newConfig);
            }
            setLoading(false);
        };
        fetchConfig();
    }, []);

    const handleSave = async () => {
        setLoading(true);
        try {
            // Upsert the configuration into app_config
            const updates = [
                { key: 'payment_info', value: config.payment_info },
                { key: 'pricing', value: config.pricing },
                { key: 'welcome_message', value: config.welcome_message },
                { key: 'support', value: config.support }
            ];

            for (let up of updates) {
                await supabase.from('app_config').upsert({ key: up.key, value: up.value, updated_at: new Date().toISOString() });
            }

            alert('تم حفظ الإعدادات بنجاح!');
        } catch (e: any) {
            alert('حدث خطأ أثناء الحفظ: ' + e.message);
        }
        setLoading(false);
    };

    if (loading) return <div className="text-center p-10 mt-20 text-gray-500">جاري التحميل...</div>;

    return (
        <div className="space-y-6 max-w-4xl mx-auto">
            <div className="flex justify-between items-center mb-8">
                <h2 className="text-3xl font-bold">إعدادات التطبيق</h2>
                <button
                    onClick={handleSave}
                    disabled={loading}
                    className="bg-primary hover:bg-primary/90 text-white px-6 py-3 rounded-lg font-bold flex items-center gap-2 transition-colors disabled:opacity-50"
                >
                    <Save size={20} />
                    <span>حفظ التغييرات</span>
                </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                {/* Payment Settings */}
                <div className="bg-surface p-6 rounded-xl border border-gray-800 space-y-4">
                    <h3 className="text-xl font-bold border-b border-gray-800 pb-2 mb-4">معلومات الدفع (زين كاش)</h3>
                    <div>
                        <label className="block text-sm text-gray-400 mb-2">رقم الهاتف لاستقبال الأموال</label>
                        <input
                            type="text"
                            value={config.payment_info?.zain_cash_number || ''}
                            onChange={(e) => setConfig({ ...config, payment_info: { ...config.payment_info, zain_cash_number: e.target.value } })}
                            className="w-full bg-background border border-gray-700 rounded-lg px-4 py-2 text-white"
                            dir="ltr"
                        />
                    </div>
                    <div>
                        <label className="block text-sm text-gray-400 mb-2">اسم صاحب الحساب</label>
                        <input
                            type="text"
                            value={config.payment_info?.account_holder || ''}
                            onChange={(e) => setConfig({ ...config, payment_info: { ...config.payment_info, account_holder: e.target.value } })}
                            className="w-full bg-background border border-gray-700 rounded-lg px-4 py-2 text-white"
                        />
                    </div>
                </div>

                {/* Pricing Settings */}
                <div className="bg-surface p-6 rounded-xl border border-gray-800 space-y-4">
                    <h3 className="text-xl font-bold border-b border-gray-800 pb-2 mb-4">أسعار الباقات (دينار عراقي)</h3>
                    <div>
                        <label className="block text-sm text-gray-400 mb-2">سعر الباقة الشهرية</label>
                        <input
                            type="number"
                            value={config.pricing?.monthly || 0}
                            onChange={(e) => setConfig({ ...config, pricing: { ...config.pricing, monthly: parseInt(e.target.value) || 0 } })}
                            className="w-full bg-background border border-gray-700 rounded-lg px-4 py-2 text-white"
                            dir="ltr"
                        />
                    </div>
                    <div>
                        <label className="block text-sm text-gray-400 mb-2">سعر الباقة السنوية</label>
                        <input
                            type="number"
                            value={config.pricing?.yearly || 0}
                            onChange={(e) => setConfig({ ...config, pricing: { ...config.pricing, yearly: parseInt(e.target.value) || 0 } })}
                            className="w-full bg-background border border-gray-700 rounded-lg px-4 py-2 text-white"
                            dir="ltr"
                        />
                    </div>
                </div>

                {/* Support Settings */}
                <div className="bg-surface p-6 rounded-xl border border-gray-800 space-y-4">
                    <h3 className="text-xl font-bold border-b border-gray-800 pb-2 mb-4">أرقام الدعم الفني</h3>
                    <div>
                        <label className="block text-sm text-gray-400 mb-2">رقم واتساب للدعم</label>
                        <input
                            type="text"
                            value={config.support?.whatsapp || ''}
                            onChange={(e) => setConfig({ ...config, support: { ...config.support, whatsapp: e.target.value } })}
                            className="w-full bg-background border border-gray-700 rounded-lg px-4 py-2 text-white"
                            dir="ltr"
                        />
                    </div>
                </div>

                {/* Welcome Message Settings */}
                <div className="bg-surface p-6 rounded-xl border border-gray-800 space-y-4">
                    <h3 className="text-xl font-bold border-b border-gray-800 pb-2 mb-4">رسالة الترحيب في التطبيق</h3>
                    <div>
                        <label className="block text-sm text-gray-400 mb-2">العنوان</label>
                        <input
                            type="text"
                            value={config.welcome_message?.title || ''}
                            onChange={(e) => setConfig({ ...config, welcome_message: { ...config.welcome_message, title: e.target.value } })}
                            className="w-full bg-background border border-gray-700 rounded-lg px-4 py-2 text-white"
                        />
                    </div>
                    <div>
                        <label className="block text-sm text-gray-400 mb-2">النص التعريفي (الرسالة)</label>
                        <textarea
                            rows={4}
                            value={config.welcome_message?.body || ''}
                            onChange={(e) => setConfig({ ...config, welcome_message: { ...config.welcome_message, body: e.target.value } })}
                            className="w-full bg-background border border-gray-700 rounded-lg px-4 py-2 text-white resize-none"
                        />
                    </div>
                </div>
            </div>
        </div>
    );
}
