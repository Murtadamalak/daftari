import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../store/AuthContext';
import { Lock } from 'lucide-react';

export default function Login() {
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const { login } = useAuth();
    const navigate = useNavigate();

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (login(password)) {
            navigate('/');
        } else {
            setError('كلمة السر غير صحيحة');
        }
    };

    return (
        <div className="min-h-screen bg-background flex items-center justify-center p-4 text-gray-100" dir="rtl">
            <div className="bg-surface w-full max-w-md p-8 rounded-2xl shadow-xl border border-gray-800">
                <div className="flex justify-center mb-6">
                    <div className="w-16 h-16 bg-primary/20 rounded-full flex items-center justify-center">
                        <Lock className="w-8 h-8 text-primary" />
                    </div>
                </div>

                <h2 className="text-2xl font-bold text-center mb-8">تسجيل الدخول للإدارة</h2>

                <form onSubmit={handleSubmit} className="space-y-6">
                    <div>
                        <label className="block text-sm font-medium text-gray-400 mb-2">
                            كلمة السر
                        </label>
                        <input
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            className="w-full bg-background border border-gray-700 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-primary transition-colors text-left"
                            dir="ltr"
                        />
                    </div>

                    {error && (
                        <div className="text-danger text-sm font-medium bg-danger/10 p-3 rounded-lg border border-danger/20">
                            {error}
                        </div>
                    )}

                    <button
                        type="submit"
                        className="w-full bg-primary hover:bg-primary/90 text-white font-bold py-3 px-4 rounded-lg transition-colors"
                    >
                        دخول
                    </button>
                </form>
            </div>
        </div>
    );
}
