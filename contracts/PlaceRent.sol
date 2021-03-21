// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/**
 * @title PlaceRent
 * @dev Rent place over the ethereum blockchain
 */
contract PlaceRent {
    address owner;

    enum Availability {AVAILABLE, BOOKED}

    enum PlaceType {APPARTMENT, BOOKED}

    enum Status {OPEN, VALIDATE, CANCELLED}

    /* Error */
    uint256[] Errors = [
        "NOT_FOUND",
        "NOT_OWNER",
        "NOT_ENOUGH_FUNDS",
        "WRONG_PRICE"
    ];

    struct Place {
        uint24 streetNumber;
        string streetName;
        uint24 postalCode;
        string city;
        uint16 aptNumber;
        string description;
        Availability availability;
        uint256 priceByNight;
        address owner;
        bool exists;
    }

    struct Booking {
        uint256 startDate;
        uint256 endDate;
        Status status;
        uint256 placeId;
        address customer;
        uint256 finalCost;
        uint256 time;
        bool exists;
    }

    /* mapping */
    Place[] places;
    Booking[] bookings;

    /* events */
    event PlaceCreated(uint256 indexed placeId, address indexed owner);
    event BookingCreated(
        uint256 indexed bookingId,
        uint256 indexed placeId,
        address indexed customer
    );

    constructor() {
        owner = msg.sender;
    }

    /* registers and validates place */
    function createPlace(
        uint24 streetNumber,
        string memory streetName,
        uint24 postalCode,
        string memory city,
        uint16 aptNumber,
        string memory description,
        uint256 priceByNight
    ) public {
        Place memory place =
            Place({
                streetNumber: streetNumber,
                streetName: streetName,
                postalCode: postalCode,
                city: city,
                aptNumber: aptNumber,
                description: description,
                availability: Availability.AVAILABLE,
                priceByNight: priceByNight,
                owner: msg.sender,
                exists: true
            });

        places.push(place);
    }

    function createBooking(
        uint256 placeId,
        uint256 startDate,
        uint256 endDate
    ) public payable isNotPlaceOwner(places[placeId]) {
        require(places[placeId].exists, Errors[0]);
        require(msg.value > 0, Errors[2]);

        uint256 diff = (endDate - startDate) / 60 / 60 / 24;

        //require(diff > places[placeId].min);

        uint256 price = diff * places[placeId].priceByNight;

        require(msg.value == price, Errors[3]);

        Booking memory booking =
            Booking({
                startDate: startDate,
                endDate: endDate,
                status: Status.OPEN,
                placeId: placeId,
                finalCost: price,
                time: block.timestamp,
                customer: msg.sender,
                exists: true
            });

        bookings.push(booking);
    }

    function getBooking(uint256 bookingId)
        public
        view
        returns (
            uint256 startDate,
            uint256 endDate,
            Status status,
            uint256 placeId,
            uint256 finalCost,
            uint256 time
        )
    {
        require(bookings[bookingId].exists, Errors[0]);

        return (
            bookings[bookingId].startDate,
            bookings[bookingId].endDate,
            bookings[bookingId].status,
            bookings[bookingId].placeId,
            bookings[bookingId].finalCost,
            bookings[bookingId].time
        );
    }

    function getPlace(uint256 placeId)
        public
        view
        returns (
            string memory description,
            string memory streetName,
            string memory city,
            Availability availability,
            uint256 priceByNight
        )
    {
        require(places[placeId].exists, Errors[0]);

        return (
            places[placeId].description,
            places[placeId].streetName,
            places[placeId].city,
            places[placeId].availability,
            places[placeId].priceByNight
        );
    }

    function cancelBooking(uint256 bookingId) public payable {
        require(bookings[bookingId].exists, Errors[0]);
        require(bookings[bookingId].customer == msg.sender, Errors[1]);

        uint256 placeId = bookings[bookingId].placeId;
        uint256 startDate = bookings[bookingId].startDate;
        address payable customer = payable(bookings[bookingId].customer);
        address payable placeowner = payable(places[placeId].owner);
        uint256 finalCost = bookings[bookingId].finalCost;
        uint256 penality = 0;
        uint256 diff = (startDate - block.timestamp) / 60 / 60 / 24;

        if (customer == msg.sender) {
            if (24 >= diff) {
                penality = (finalCost * 10) / 100;
                placeowner.transfer(penality);
            }

            customer.transfer(finalCost - penality);
        } else if (placeowner == msg.sender) {
            customer.transfer(finalCost);
        }

        bookings[bookingId].status = Status.CANCELLED;
    }

    modifier isNotPlaceOwner(Place memory place) {
        require(msg.sender != place.owner);
        _;
    }

    modifier isPlaceOwner(Place memory place) {
        require(msg.sender == place.owner, Errors[1]);
        _;
    }
}
