import { requireBackend } from './supabase'

export async function findUserByEmail(email) {
  const db = requireBackend()
  const normalized = email.trim().toLowerCase()
  const { data, error } = await db.from('profiles').select('id,email,display_name,avatar_url').eq('email', normalized).maybeSingle()
  if (error) throw error
  return data
}

export async function sendMessage(conversationId, senderId, body, kind = 'text', mediaUrl = null) {
  const db = requireBackend()
  const { data, error } = await db.from('messages').insert({ conversation_id: conversationId, sender_id: senderId, body, kind, media_url: mediaUrl }).select().single()
  if (error) throw error
  return data
}

export function subscribeToMessages(conversationId, onMessage) {
  const db = requireBackend()
  const channel = db.channel(`conversation:${conversationId}`)
    .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages', filter: `conversation_id=eq.${conversationId}` }, payload => onMessage(payload.new))
    .subscribe()
  return () => db.removeChannel(channel)
}
