// Initialize Supabase client
const supabaseUrl = 'https://owrfjcjkpkugfzfpnzyp.supabase.co'; // Replace with your Supabase URL
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im93cmZqY2prcGt1Z2Z6ZnBuenlwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyNjM5ODkxNywiZXhwIjoyMDQxOTc0OTE3fQ.0WzDl3zPy1lGy8gy_StmRvGH5Rqe1A7PtPX7qsOCZcs'; // Replace with your Supabase anon key
const supabase = supabase.createClient(supabaseUrl, supabaseKey);
/* 
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im93cmZqY2prcGt1Z2Z6ZnBuenlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjYzOTg5MTcsImV4cCI6MjA0MTk3NDkxN30.vZvoo9sFwLUvHBcoSuVkS2gue4cg0RR20iTzzWc7voI



*/
// Fetch student data and populate the table
async function getStudentData() {
  try {
    const { data, error } = await supabase
      .from('student_database')
      .select('id, student_roll_number, coordinates, timestamp, is_on_campus')
      .order('timestamp', { ascending: false });

    if (error) throw error;
    console.log('Fetched Data:', data);

    // Populate the table
    populateTable(data);
  } catch (error) {
    console.error('Error fetching data:', error);
  }
}

// Populate the table with data
function populateTable(data) {
  const tableBody = document.querySelector('#student-table tbody');
  tableBody.innerHTML = ''; // Clear existing data

  data.forEach(record => {
    const row = createRow(record);
    tableBody.appendChild(row);
  });
}

// Create a table row for a given record
function createRow(record) {
  const row = document.createElement('tr');

  const rollNumberCell = document.createElement('td');
  rollNumberCell.textContent = record.student_roll_number;

  const timestampCell = document.createElement('td');
  timestampCell.textContent = formatTimestamp(record.timestamp);

  const statusCell = document.createElement('td');
  statusCell.textContent = record.is_on_campus ? 'On Campus' : 'Off Campus';
  statusCell.classList.add(record.is_on_campus ? 'status-on-campus' : 'status-off-campus');

  row.appendChild(rollNumberCell);
  row.appendChild(timestampCell);
  row.appendChild(statusCell);
  row.setAttribute('data-id', record.id); // Set a unique ID for the row
  return row;
}

// Convert timestamp to a more readable format
function formatTimestamp(timestamp) {
  const date = new Date(timestamp);
  return date.toLocaleString(); // Outputs in a user-friendly format
}

// Real-time subscription to student_database changes
supabase
  .channel('student_database_changes')
  .on(
    'postgres_changes',
    { event: '*', schema: 'public', table: 'student_database' },
    (payload) => {
      console.log('Change received:', payload);
      handleRealtimeChange(payload);
    }
  )
  .subscribe();

// Handle real-time database changes
function handleRealtimeChange(payload) {
  const tableBody = document.querySelector('#student-table tbody');
  const { new: newData } = payload; // Get new data from payload

  // Check if the record already exists in the table
  const existingRow = document.querySelector(`tr[data-id="${newData.id}"]`);
  if (existingRow) {
    // Update the existing row
    existingRow.replaceWith(createRow(newData));
  } else {
    // Add a new row
    tableBody.appendChild(createRow(newData));
  }
}

// Initial data fetch
getStudentData();
