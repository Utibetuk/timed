"reach 0.1";


const Common = {
    seeBid: Fun([Address, UInt], Null),
    showOutcome: Fun([Address, UInt], Null),
}
export const main = Reach.App(() => {
    const Creator = Participant('Creator', {
        ...Common,
        getSale: Fun([], Object({
            nftId: Token,
            minBid: UInt,
            deadline: UInt,
        })),
        auctionReady: Fun([], Null),
        get_Address: Fun([UInt], Address),
        get_bid: Fun([Data({ "None": Null, "Some": UInt })], UInt)
    });
    const BidderView = ParticipantClass('BidderView', {
        ...Common,
        optIn: Fun([Token], Null),
    });
    const Bidder = API('Bidder', {
        bid: Fun([UInt], Tuple(Address, UInt)),

    });
    init();

    Creator.only(() => {
        const {nftId, minBid, deadline} = declassify(interact.getSale());
    });
    Creator.publish(nftId, minBid, deadline);
    const amt = 1;
    const x = new Map(Address, UInt);
    commit();
    Creator.pay([[amt, nftId]]);
    Creator.interact.auctionReady();
    BidderView.interact.optIn(nftId);
    BidderView.interact.seeBid(Creator, minBid);

    assert(balance(nftId) == amt, "balance of NFT is wrong");
    const end = lastConsensusTime() + deadline;
    const [
        bidders,
        highestBidder,
        lastPrice,
        isFirstBid,
        a
    ] = parallelReduce([0, Creator, minBid, true, array(UInt, [0, 0, 0, 0, 0])])
        .invariant(balance(nftId) == balance(nftId))
        .while(lastConsensusTime() <= end && bidders < 5 )
        .api_(Bidder.bid, (bid) => {
            
            check(bid > lastPrice, "bid is too low");
            return [ bid, (notify) => {
                x[this] = bid
                notify([highestBidder, lastPrice]);
                Creator.interact.seeBid(this, bid);
                BidderView.interact.seeBid(this, bid);
                return [bidders+1, this, bid, false, a.set(bidders, bid)];
            }];
        })
        .timeout(absoluteTime(end), () => {
          Creator.publish();
          return [bidders, highestBidder, lastPrice, isFirstBid, a];
      });
    commit();
    Creator.publish()
    var [p] = [0]
    
    invariant(balance(nftId) == balance(nftId))
    while( p < bidders ){
        commit()
        Creator.only(() => {
            const getadd = declassify(interact.get_Address(p))
        })
        Creator.publish(getadd);
        commit();
        Creator.only(() => {
            const b = declassify(interact.get_bid(x[getadd]))
        })
        Creator.publish(b)
        if (b == a.max()){

            transfer(balance(nftId), nftId).to(getadd);
            p = p + 1;
            continue
        }
        else{
            p = p + 1;
            continue
        }
    }
        transfer(balance()).to(Creator)
        transfer(balance(nftId), nftId).to(Creator)
        Creator.interact.showOutcome(highestBidder, lastPrice);
        BidderView.interact.showOutcome(highestBidder, lastPrice);
    commit();
    exit();
});
