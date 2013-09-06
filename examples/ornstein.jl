######### fitting an Ornstein–Uhlenbeck process  ###########

using DataFrames
using MCMC

# generate serie
srand(1)
duration = 1000  # 1000 time steps
mu0 = 10.        # convergence value
tau0 = 20        # convergence time
sigma0 = 0.1     # noise term

x = Array(Float64, duration)
x[1] = 1.
for i in 2:duration
	x[i] = x[i-1]*exp(-1/tau0) + mu0*(1-exp(-1/tau0)) +  sigma0*randn()
end

# model definition 
ex = quote
    tau ~ Uniform(0, 100)
    sigma ~ Uniform(0, 2)
    mu ~ Uniform(0, 20)

    fac = exp(- 1. / tau)
    resid = x[2:end] - x[1:end-1] * fac - mu * (1. - fac)
    resid ~ Normal(0, sigma)
end

m = model(ex, tau=0.05, sigma=1., mu=1., gradient=true)
m.scale = [1000., 1., 10.]  # scale hint for tau, sigma and mu, to help sampling

# run random walk metropolis (10000 steps, 1000 for burnin, setting initial values)
res = run(m * RWM(tuner=RAM()), steps=1000:10000)

describe(res.samples)
describe(res.diagnostics["accept"]) # acceptance stats

# run Hamiltonian Monte-Carlo (10000 steps, 1000 for burnin, 5 inner steps, 0.002 inner step size)
res = m * HMC(5, 0.002) * (1000:10000)

# run NUTS - HMC (1000 steps, 500 for burnin)
res = m * NUTS() * (500:1000)

describe(res.diagnostics["ndoublings"]) # check # of doublings in NUTS algo

