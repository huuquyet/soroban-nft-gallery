import * as million from 'million-contract'

export async function get({ params, request }) {
  const FakeWallet = {
    isConnected: () => false,
  }
  console.log('Calling total_supply')
  const total = await million.totalSupply({ wallet: FakeWallet })
  const uris = []
  for (let i = 0; i < total; i++) {
    const data = await million.tokenUri({ token_id: i }, { wallet: FakeWallet })
    uris.push(data)
  }
  console.log(total)
  return {
    body: JSON.stringify({
      supply: total,
      uris: uris,
    }),
  }
}
