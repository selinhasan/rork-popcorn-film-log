import { useState, useEffect } from 'react'
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ActivityIndicator } from 'react-native'
import { useAuth } from '../context/AuthContext'
import { supabase } from '../lib/supabase'

export default function RegisterScreen({ navigation }) {
  const { signUp } = useAuth()
  const [username, setUsername] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [usernameStatus, setUsernameStatus] = useState(null) // 'checking' | 'taken' | 'available' | null
  const isFormValid =
    username.trim().length >= 3 &&
    !/\s/.test(username) &&
    usernameStatus === 'available' &&
    email.trim().length > 0 &&
    password.length >= 6 &&
    password === confirmPassword

  useEffect(() => {
    if (username.length === 0) {
      setUsernameStatus(null)
      return
    }
    if (username.trim().length < 3 || /\s/.test(username)) {
      setUsernameStatus('invalid')
      return
    }

  setUsernameStatus('checking')

  const timeout = setTimeout(async () => {
    const { data } = await supabase
      .from('public_user_info')
      .select('username')
      .eq('username', username.trim().toLowerCase())
      .maybeSingle()

    setUsernameStatus(data ? 'taken' : 'available')
  }, 500)

  return () => clearTimeout(timeout)
}, [username])

  const handleRegister = async () => {
    setError('')

    if (!username || !email || !password || !confirmPassword) {
      setError('Please fill in all fields')
      return
    }
    if (username.trim().length < 3) {
      setError('Username must be at least 3 characters')
      return
    }
    if (/\s/.test(username)) {
      setError('Username cannot contain spaces')
      return
    }
    if (usernameStatus === 'taken') {
      setError('That username is already taken')
      return
    }
    if (usernameStatus === 'checking') {
      setError('Please wait while we check your username')
      return
    }
    if (password !== confirmPassword) {
      setError('Passwords do not match')
      return
    }
    if (password.length < 6) {
      setError('Password must be at least 6 characters')
      return
    }

    setLoading(true)
    try {
      const { session } = await signUp(email.trim().toLowerCase(), password, username.trim().toLowerCase())
      if (!session) {
        navigation.navigate('Login')
      }
    } catch (err) {
      setError(err.message || 'Something went wrong. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const usernameHint = () => {
  if (usernameStatus === 'invalid') {
    if (/\s/.test(username)) return { text: 'Username cannot contain spaces', color: '#e53e3e' }
    return { text: `username must be minimum 3 characters`, color: '#e53e3e' }
  }
  if (usernameStatus === 'checking') return { text: 'Checking...', color: '#999' }
  if (usernameStatus === 'taken') return { text: 'Username already taken', color: '#e53e3e' }
  if (usernameStatus === 'available') return { text: 'Username available ✓', color: '#3ECF8E' }
  return null
  }

  const hint = usernameHint()

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Create account</Text>
      <Text style={styles.subtitle}>Sign up to get started</Text>

      <TextInput
        style={[styles.input, usernameStatus === 'taken' && styles.inputError, usernameStatus === 'available' && styles.inputSuccess]}
        placeholder="Username"
        placeholderTextColor="#999"
        value={username}
        onChangeText={(t) => { setError(''); setUsername(t) }}
        autoCapitalize="none"
        autoCorrect={false}
      />
      {hint && <Text style={[styles.hint, { color: hint.color }]}>{hint.text}</Text>}

      <TextInput
        style={styles.input}
        placeholder="Email"
        placeholderTextColor="#999"
        value={email}
        onChangeText={(t) => { setError(''); setEmail(t) }}
        autoCapitalize="none"
        keyboardType="email-address"
        autoComplete="email"
      />
      <TextInput
        style={styles.input}
        placeholder="Password"
        placeholderTextColor="#999"
        value={password}
        onChangeText={(t) => { setError(''); setPassword(t) }}
        secureTextEntry
      />
      <TextInput
        style={styles.input}
        placeholder="Confirm password"
        placeholderTextColor="#999"
        value={confirmPassword}
        onChangeText={(t) => { setError(''); setConfirmPassword(t) }}
        secureTextEntry
      />

      {error ? <Text style={styles.error}>{error}</Text> : null}

      <TouchableOpacity
        style={[styles.button, !isFormValid && styles.buttonDisabled]}
        onPress={handleRegister}
        disabled={loading || !isFormValid}
        >
        {loading
        ? <ActivityIndicator color="#fff" />
        : <Text style={styles.buttonText}>Create account</Text>
        }    
      </TouchableOpacity>

      <TouchableOpacity onPress={() => navigation.navigate('Login')}>
        <Text style={styles.link}>Already have an account? <Text style={styles.linkBold}>Sign in</Text></Text>
      </TouchableOpacity>
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    paddingHorizontal: 28,
    backgroundColor: '#fff',
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: '#111',
    marginBottom: 6,
  },
  subtitle: {
    fontSize: 15,
    color: '#666',
    marginBottom: 32,
  },
  input: {
    borderWidth: 1,
    borderColor: '#e0e0e0',
    borderRadius: 10,
    paddingHorizontal: 16,
    paddingVertical: 13,
    fontSize: 15,
    color: '#111',
    marginBottom: 4,
    backgroundColor: '#fafafa',
  },
  inputError: {
    borderColor: '#e53e3e',
  },
  inputSuccess: {
    borderColor: '#3ECF8E',
  },
  hint: {
    fontSize: 12,
    marginBottom: 10,
    marginLeft: 4,
  },
  error: {
    color: '#e53e3e',
    fontSize: 13,
    marginBottom: 12,
    textAlign: 'center',
  },
  button: {
    backgroundColor: '#3ECF8E',
    borderRadius: 10,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 6,
    marginBottom: 24,
  },
  buttonText: {
    color: '#fff',
    fontSize: 15,
    fontWeight: '600',
  },
  link: {
    textAlign: 'center',
    color: '#666',
    fontSize: 14,
  },
  linkBold: {
    color: '#3ECF8E',
    fontWeight: '600',
  },
  buttonDisabled: {
  backgroundColor: '#c0c0c0',
  },
})
