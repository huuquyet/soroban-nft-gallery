import { promises as fs } from 'node:fs'
import { Keypair, verify } from '@stellar/stellar-sdk'
import * as million from 'million-contract'

const FakeWallet = {
  isConnected: () => false,
}

export async function get({ params, request }) {
  const id = params.id
  if (!id.startsWith('0x')) {
    return new Response(null, { status: 404 })
  }

  const filename = `./data/data-${id}.json`
  let data = {
    name: id,
    description: '',
    image: `${import.meta.env.SITE}${import.meta.env.BASE_URL}question.png`,
    home_page: `${import.meta.env.SITE}${import.meta.env.BASE_URL}test/${id}`,
  }
  try {
    data = JSON.parse(await fs.readFile(filename, 'utf8'))
  } catch (e) {
    const xy = await million.coords({ token_id: 0 })
    data.coords = xy
    fs.writeFile(filename, JSON.stringify(data))
  }

  return {
    body: JSON.stringify(data),
  }
}

export const post: APIRoute = async ({ params, request }) => {
  const id = params.id
  console.log(`recv ${id}`)
  console.log(request.headers.get('Content-Type'))
  if (id.startsWith('0x') && request.headers.get('Content-Type') === 'application/json') {
    const token_id = parseInt(id.substring(2), 16)
    const owner = await million.ownerOf({ token_id: token_id }, { wallet: FakeWallet })

    const body = await request.json()
    const kp = Keypair.fromPublicKey(owner)
    console.log(kp)
    const verified = kp.verify(Buffer.from(body.data, 'base64'), Buffer.from(body.signature, 'hex'))

    if (verified) {
      const filename = `./data/data-${id}.json`
      let data = {
        name: id,
        description: '',
        image: `${import.meta.env.SITE}${import.meta.env.BASE_URL}question.png`,
        home_page: `${import.meta.env.SITE}${import.meta.env.BASE_URL}test/${id}`,
      }
      try {
        data = JSON.parse(await fs.readFile(filename, 'utf8'))
        data.image = Buffer.from(body.data, 'base64').toString()
      } catch (e) {
        console.log('Error writing json')
      }
      fs.writeFile(filename, JSON.stringify(data))
      return new Response(
        JSON.stringify({
          verified: verified,
        }),
        {
          status: 200,
        }
      )
    }
  }
  return new Response(null, { status: 400 })
}
