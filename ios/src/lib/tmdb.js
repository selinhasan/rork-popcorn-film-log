const BASE_URL = 'https://api.themoviedb.org/3'
const IMAGE_BASE = 'https://image.tmdb.org/t/p/w500'
const API_KEY = process.env.EXPO_PUBLIC_TMDB_API_KEY || ''

async function get(path, params = {}) {
  const query = new URLSearchParams({ api_key: API_KEY, ...params }).toString()
  const res = await fetch(`${BASE_URL}${path}?${query}`)
  if (!res.ok) throw new Error(`TMDb error ${res.status}`)
  return res.json()
}

function movieToFilm(item, genres = []) {
  const isTV = item.media_type === 'tv' || item.name !== undefined
  const genreNames = (item.genre_ids || [])
    .map(id => genres.find(g => g.id === id)?.name)
    .filter(Boolean)
  return {
    id: String(item.id),
    title: item.title || item.name || 'Unknown',
    year: (item.release_date || item.first_air_date || '').slice(0, 4),
    genre: genreNames,
    director: '',
    cast: [],
    synopsis: item.overview || '',
    posterURL: item.poster_path ? `${IMAGE_BASE}${item.poster_path}` : '',
    runtime: '',
    isTV,
    averageRating: item.vote_average ? parseFloat((item.vote_average / 2).toFixed(1)) : 0,
  }
}

export async function getTrending(genres = []) {
  const data = await get('/trending/movie/week')
  return data.results.map(m => movieToFilm(m, genres))
}

export async function getPopular(genres = []) {
  const data = await get('/movie/popular')
  return data.results.map(m => movieToFilm(m, genres))
}

export async function getTopRated(genres = []) {
  const data = await get('/movie/top_rated')
  return data.results.map(m => movieToFilm(m, genres))
}

export async function searchMulti(query, genres = []) {
  const data = await get('/search/multi', { query, include_adult: false })
  return data.results
    .filter(r => r.media_type === 'movie' || r.media_type === 'tv')
    .map(m => movieToFilm(m, genres))
}

export async function getGenres() {
  const [movies, tv] = await Promise.all([
    get('/genre/movie/list'),
    get('/genre/tv/list'),
  ])
  const all = [...movies.genres, ...tv.genres]
  const seen = new Set()
  return all.filter(g => {
    if (seen.has(g.id)) return false
    seen.add(g.id)
    return true
  })
}

export async function discoverFilms(genreId, sortBy = 'popularity.desc', genres = []) {
  const params = { sort_by: sortBy, include_adult: false }
  if (genreId) params.with_genres = genreId
  const data = await get('/discover/movie', params)
  return data.results.map(m => movieToFilm(m, genres))
}

export async function getMovieDetail(id, genres = []) {
  const [detail, credits] = await Promise.all([
    get(`/movie/${id}`),
    get(`/movie/${id}/credits`),
  ])
  const director = credits.crew?.find(c => c.job === 'Director')?.name || ''
  const cast = credits.cast?.slice(0, 6).map(c => c.name) || []
  const genreNames = (detail.genres || []).map(g => g.name)
  const runtime = detail.runtime ? `${detail.runtime}m` : ''
  return {
    id: String(detail.id),
    title: detail.title || detail.name || 'Unknown',
    year: (detail.release_date || '').slice(0, 4),
    genre: genreNames,
    director,
    cast,
    synopsis: detail.overview || '',
    posterURL: detail.poster_path ? `${IMAGE_BASE}${detail.poster_path}` : '',
    runtime,
    isTV: false,
    averageRating: detail.vote_average
      ? parseFloat((detail.vote_average / 2).toFixed(1))
      : 0,
  }
}
