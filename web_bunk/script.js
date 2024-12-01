// Campus Polygon (defined based on your provided coordinates)
const campusPolygon = [
    [73.8518061, 24.6209523],
    [73.8520743, 24.6182701],
    [73.8569237, 24.6186603],
    [73.8565375, 24.6215278],
    [73.8518061, 24.6209523] // Closing the polygon
];

// Function to check if coordinates are inside the campus polygon
function isInsideCampus(lat, lon) {
    let intersections = 0;
    for (let i = 0; i < campusPolygon.length - 1; i++) {
        const [x1, y1] = campusPolygon[i];
        const [x2, y2] = campusPolygon[i + 1];
        if (((lat > y1) !== (lat > y2)) && (lon < (x2 - x1) * (lat - y1) / (y2 - y1) + x1)) {
            intersections++;
        }
    }
    return intersections % 2 !== 0;
}

// Function to handle CSV file upload and parse it
document.getElementById('csv-file').addEventListener('change', function(e) {
    const file = e.target.files[0];

    if (file) {
        // Use PapaParse to parse the CSV file
        Papa.parse(file, {
            complete: function(results) {
                const data = results.data; // Parsed CSV data
                populateTable(data);
            },
            header: true, // Assuming the first row of CSV contains column names
            skipEmptyLines: true
        });
    }
});

// Function to format timestamp into separate Date and Time
function formatTimestamp(timestamp) {
    const dateObj = new Date(timestamp);
    
    const options = {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
    };
    const date = dateObj.toLocaleDateString('en-GB', options); // Date in DD/MM/YYYY format

    const timeOptions = {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false, // For 24-hour time
    };
    const time = dateObj.toLocaleTimeString('en-GB', timeOptions); // Time in HH:mm:ss format

    return { date, time };
}

// Function to populate the table with parsed data
function populateTable(data) {
    const tableBody = document.querySelector('#student-table tbody');
    tableBody.innerHTML = ''; // Clear previous rows

    data.forEach(row => {
        const coordinates = row.coordinates.split(", ");
        const lat = parseFloat(coordinates[0]);
        const lon = parseFloat(coordinates[1]);

        const isOnCampus = isInsideCampus(lat, lon);
        const onCampusText = isOnCampus ? 'Yes' : 'No';
        const onCampusClass = isOnCampus ? 'true' : 'false';

        // Format the timestamp into date and time
        const { date, time } = formatTimestamp(row.timestamp);

        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>${row.student_roll_number}</td>
            <td>${row.coordinates}</td>
            <td>${date}</td> <!-- Date column -->
            <td>${time}</td> <!-- Time column -->
            <td class="${onCampusClass}">${onCampusText}</td>
        `;
        tableBody.appendChild(tr);
    });
}

// Implementing search by roll number
document.getElementById('search-roll').addEventListener('input', function(e) {
    const filterValue = e.target.value.toLowerCase();
    const rows = document.querySelectorAll('#student-table tbody tr');

    rows.forEach(row => {
        const rollNumber = row.cells[0].textContent.toLowerCase();
        if (rollNumber.includes(filterValue)) {
            row.style.display = '';
        } else {
            row.style.display = 'none';
        }
    });
});

// Implementing filter by Date
document.getElementById('search-date').addEventListener('input', function(e) {
    const filterValue = e.target.value.toLowerCase();
    const rows = document.querySelectorAll('#student-table tbody tr');

    rows.forEach(row => {
        const date = row.cells[2].textContent.toLowerCase();
        if (date.includes(filterValue)) {
            row.style.display = '';
        } else {
            row.style.display = 'none';
        }
    });
});

// Implementing filter by Time
document.getElementById('search-time').addEventListener('input', function(e) {
    const filterValue = e.target.value.toLowerCase();
    const rows = document.querySelectorAll('#student-table tbody tr');

    rows.forEach(row => {
        const time = row.cells[3].textContent.toLowerCase();
        if (time.includes(filterValue)) {
            row.style.display = '';
        } else {
            row.style.display = 'none';
        }
    });
});
