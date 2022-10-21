'reach 0.1'

const[finalResult, Y_WINS, Z_WINS, DRAW] = makeEnum(3);

const winner = (handY, handZ, guessY, guessZ) => {
    if(guessY == guessZ){
        return DRAW;
    } else {
        if ((handY + handZ) == guessY){
            return Y_WINS;
        } else {
            if((handY + handZ) == guessZ){
                return Z_WINS;
            } else {
                return DRAW;
            }
        }
    }
};
assert(winner(3, 0, 3, 0) == Y_WINS);
assert(winner(0, 3, 0, 3) == Z_WINS);
assert(winner(0, 2, 1, 3) == DRAW);
assert(winner(3, 3, 3, 3) == DRAW);

forall(UInt, handY =>
    forall(UInt, handZ =>
        forall(UInt, guessY =>
            forall(UInt, guessZ =>
                assert(finalResult(winner(handY, handZ, guessY, guessZ)))))));

forall(UInt, handY =>
    forall(UInt, handZ =>
        forall(UInt, guess =>
            assert(winner(handY, handZ, guess, guess) == DRAW))));

const Player = {
    ...hasRandom, 
    getHand : Fun([], UInt),
    getGuess : Fun([], UInt),
    seeOutcome : Fun([UInt], Null),
    informTimeout : Fun([], Null),
};

export const main = Reach.App(() =>{
    const Yoga = Participant ('Yoga', {
        ...Player,
        wager : UInt,
        deadline : UInt,
    });
    const Zack = Participant ('Zack', {
        ...Player,
        acceptWager : Fun([UInt], Null),
    });
    init();

    const informTimeout = () => {
        each([Yoga, Zack], () => {
            interact.informTimeout()
        });
    };

    Yoga.only(() => { 
        const amount = declassify(interact.wager);
        const deadline = declassify(interact.deadline);
    });
    Yoga.publish(amount, deadline)
        .pay(amount);
        commit();

    Zack.interact.acceptWager(amount);
    Zack.pay(amount)
        .timeout(relativeTime(deadline), () => closeTo(Yoga, informTimeout));

    var result = DRAW;
    invariant(balance() == 2 * amount && finalResult(result));
    while (result == DRAW) {
        commit();

        Yoga.only(() => {
            const _handY = interact.getHand();
            const _guessY = interact.getGuess();

            const [_commitY, _saltY] = makeCommitment(interact, _handY);
            const commitY = declassify(_commitY);
            const [_guessCommitY, _guessSaltY] = makeCommitment(interact, _guessY);
            const guessCommitY = declassify(_guessCommitY)
        });
        Yoga.publish(commitY, guessCommitY)
            .timeout(relativeTime(deadline), () => closeTo(Zack, informTimeout));
            commit();

        unknowable(Zack, Yoga (_handY, _saltY));
        unknowable(Zack, Yoga (_guessY, _guessSaltY));

        Albert.only(() => {
            const _handZ = interact.getHand();
            const _guessZ = interact.getGuess();
            const handZ = declassify(_handZ)
            const guessZ = declassify(_guessZ);
        });
        Albert.publish(handZ, guessZ)
            .timeout(relativeTime(deadline), () => closeTo(Yoga, informTimeout));
            commit()
        
        Rose.only(() => {
            const [saltY, handY] = declassify([_saltY, _handY]);
            const [guessSaltY, guessY] = declassify([_guessSaltY, _guessY]);
        })

        Rose.publish(saltY, handY, guessSaltY, guessY)
            .timeout(relativeTime(deadline), () => closeTo(Zack, informTimeout));

        checkCommitment(commitY, saltY, handY)
        checkCommitment(guessCommitY, guessSaltY, guessY)

        result = winner(handY, handZ, guessY, guessZ);
        continue;
    }
    assert(result == Y_WINS || result == Z_WINS);

    transfer(2 * amount).to(result == Y_WINS ? Yoga : Zack)
     commit()

    each([Rose, Albert], () => {
        interact.seeOutcome(result)
    });

    exit();
});
