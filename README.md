# million lumen homepage

Demo: [https://millionlumenhomepage.art](https://millionlumenhomepage.art)

## How to launch the dApp on standalone

### 1. Build the contract

Go to mlh-contract

```
cd ./mlh-contract
```

Then run the build with `make`.

> You will see that the Makefile build two contracts, the first one is to
> initialize the contract, the second one is the actual contract without
> the initialize() function. This allows to remove the only called once
> function from the contract.

This creates 2 wasm files in mlh-frontend/target

### 2. Launch the standalone network

Go to mlh-contract and run the standalone.sh script.

### 3. Deploying the contracts

For now on, we will move to the mlh-frontend folder.

First, we need to configure the soroban cli, if you don't have it, you can install using `cargo install soroban-cli`.

```
soroban config network add standalone \
    --rpc-url http://localhost:8000/soroban/rpc \
    --network-passphrase "Standalone Network ; February 2017"
```

We also need an account to set everything up

```
soroban config identity generate admin
```

We need to fund this account

```
curl "http://localhost:8000/friendbot?addr=$(soroban config identity address admin)"
```

We need to wrap the asset we will use when minting the NFT. Here
we will simply wrap the native asset, feel free to experiment with other
custom assets.

```
soroban lab token wrap --asset native --network standalone --source admin
```

#### Deploy the init contract

```
soroban contract deploy --wasm ./target/milltion-init.wasm \
    --source admin \
    --network standalone
```

This returns the $CONTRACT_ID.

We can now invoke the initialize function:

```
soroban contract invoke --id $CONTRACT_ID --source admin \
    --network standalone \
    -- initialize \
	--admin admin \
	--asset $(soroban lab token id --asset native --network standalone) \
	--price 2560000000
```

#### Install the actual contract

```
soroban contract install \
    --wasm ./target/milltion-prod.wasm \
    --source admin \
    --network standalone
```

This will return a sha256 hash that is the $WASM_HASH we need
to upgrade the contract.

#### Upgrade the contract

```
soroban contract invoke --id $CONTRACT_ID \
    --source admin \
    --network standalone \
    -- upgrade \
    --wasm_hash $WASM_HASH
```

Now the contract is fully initialized and can be use.

### 4. Launching the frontend

```
rm -r data                                # remove the data folder
rm -r node_modules                        # delete the node_modules folder
                                          # to remove previous contract id
                                          # references

npm i                                     # install all deps

# generate the contract bindings
soroban contract bindings typescript \
    --wasm ./target/milltion-prod.wasm \
	--network standalone \
	--contract-id $CONTRACT_ID \
	--contract-name Million \
	--output-dir node_modules/Million

mkdir data   # create the data folder
npm run dev  # launch astro
```

### Frontend
# Astro Starter Kit: Basics

```
npm create astro@latest -- --template basics
```

[![Open in StackBlitz](https://developer.stackblitz.com/img/open_in_stackblitz.svg)](https://stackblitz.com/github/withastro/astro/tree/latest/examples/basics)
[![Open with CodeSandbox](https://assets.codesandbox.io/github/button-edit-lime.svg)](https://codesandbox.io/p/sandbox/github/withastro/astro/tree/latest/examples/basics)
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/withastro/astro?devcontainer_path=.devcontainer/basics/devcontainer.json)

> 🧑‍🚀 **Seasoned astronaut?** Delete this file. Have fun!

![just-the-basics](https://github.com/withastro/astro/assets/2244813/a0a5533c-a856-4198-8470-2d67b1d7c554)

## 🚀 Project Structure

Inside of your Astro project, you'll see the following folders and files:

```
/
├── public/
│   └── favicon.svg
├── src/
│   ├── components/
│   │   └── Card.astro
│   ├── layouts/
│   │   └── Layout.astro
│   └── pages/
│       └── index.astro
└── package.json
```

Astro looks for `.astro` or `.md` files in the `src/pages/` directory. Each page is exposed as a route based on its file name.

There's nothing special about `src/components/`, but that's where we like to put any Astro/React/Vue/Svelte/Preact components.

Any static assets, like images, can be placed in the `public/` directory.

## 🧞 Commands

All commands are run from the root of the project, from a terminal:

| Command                   | Action                                           |
| :------------------------ | :----------------------------------------------- |
| `npm install`             | Installs dependencies                            |
| `npm run dev`             | Starts local dev server at `localhost:3000`      |
| `npm run build`           | Build your production site to `./dist/`          |
| `npm run preview`         | Preview your build locally, before deploying     |
| `npm run astro ...`       | Run CLI commands like `astro add`, `astro check` |
| `npm run astro -- --help` | Get help using the Astro CLI                     |

## 👀 Want to learn more?

Feel free to check [our documentation](https://docs.astro.build) or jump into our [Discord server](https://astro.build/chat).
