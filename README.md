Comstock
========

The Future of Buying Bitcoin (for me, anyway)
--------

Since the price of bitcoin will never fall, ever, I'm using a very basic
long strategy of buying when the price dips.  I'd encourage you to use this at your
own risk, as it's in no way stable (yet).  

I like the idea of passively buying bitcoin because I'm extremely bullish on its
future, and I just started playing with the [Bitfloor API](https://bitfloor.com/docs/api).  
Eventually, I'd like to incorporate historical data and use a more sophisticated strategy.

How Do I Use This Thing?
--------

I'm using **redis** as a datastore, so you'll need to install that:

    brew install redis

Next, I'm using the wonderful **HTTParty** gem for pulling data from the REST API:

    gem install httparty

Lastly, update **keys.json** to use your own API key / secret (ports must be 443 for https)

You can run the trader from the command line, as I haven't gotten around to building a decent
CLI (yet)

Contribute
---------

Pull requests are more than welcome, as usual:

1. Fork this repo

2. Create a branch with excellent code (`git checkout -b excellence`)

3. Commit the new code, push to your forked repo (`git push origin excellence`)

4. Create a pull request, and I promise I'll look at it

