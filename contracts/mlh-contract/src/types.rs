use soroban_sdk::{contracttype, Env, IntoVal, TryFromVal, Val};
#[contracttype]
pub enum MillionDataKey {
    TokenId,
    AssetAddress,
    Price,
}
impl storage::Storage for MillionDataKey {
    fn get<V: TryFromVal<Env, Val>>(&self, env: &Env) -> Option<V> {
        storage::Instance::get(env, self)
    }

    fn set<V: IntoVal<Env, Val>>(&self, env: &Env, val: &V) {
        storage::Instance::set(env, self, val)
    }

    fn has(&self, env: &Env) -> bool {
        storage::Instance::has(env, self)
    }

    fn extend(&self, env: &Env, min_ledger_to_live: u32) -> &Self {
        storage::Instance::extend(env, min_ledger_to_live);
        self
    }

    fn remove(&self, env: &Env) {
        storage::Instance::remove(env, self)
    }
}

#[contracttype]
pub enum Coords {
    Token(u32, u32),
    Xy(u32),
}
impl storage::Storage for Coords {
    fn get<V: TryFromVal<Env, Val>>(&self, env: &Env) -> Option<V> {
        storage::Persistent::get(env, self)
    }

    fn set<V: IntoVal<Env, Val>>(&self, env: &Env, val: &V) {
        storage::Persistent::set(env, self, val)
    }

    fn has(&self, env: &Env) -> bool {
        storage::Persistent::has(env, self)
    }

    fn extend(&self, env: &Env, min_ledger_to_live: u32) -> &Self {
        storage::Persistent::extend(env, self, min_ledger_to_live);
        self
    }

    fn remove(&self, env: &Env) {
        storage::Persistent::remove(env, self)
    }
}
/*
#[contracterror]
#[derive(Copy, Clone, Debug, PartialEq)]
pub enum MillionError {
    Exhausted = 1,
}
*/
