import os
from flask import Flask, render_template, request, jsonify
import sqlite3

from opustools import DbOperations

app = Flask(__name__)

@app.route('/opusapi/')
def opusapi():
    dbo = DbOperations(db_file=os.environ['OPUSAPI_DB'])

    parameters = request.args.copy()
    parameters = dbo.clean_up_parameters(parameters)
    total_params = request.args.copy()
     
    if len(parameters) == 0:
        baseurl = 'http://opus.nlpl.eu/opusapi/'
        #baseurl='http://127.0.0.1:5000/opusapi/'
        return render_template('opusapi.html', baseurl=baseurl)

    if 'total' in total_params.keys():
        try:
            conn = sqlite3.connect(os.environ['OPUSAPI_DB'])
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
                
            query = """
                SELECT * FROM opusfile
                WHERE preprocessing LIKE '%xml%'
                AND latest LIKE '%True%'
                AND LOWER(corpus) NOT LIKE '%elra%'
                AND LOWER(corpus) NOT LIKE '%elrc%'
            """
                
            cursor.execute(query)
            results = cursor.fetchall()


            result = [dict(row) for row in results]

            return jsonify(result)
                
        except sqlite3.Error as e:
            return jsonify({'error': f'Database error: {str(e)}'}), 500
        except Exception as e:
            return jsonify({'error': f'Server error: {str(e)}'}), 500
        finally:
            if 'conn' in locals():
                conn.close()


    if 'corpora' in parameters.keys():
        return jsonify(corpora=dbo.run_corpora_query(parameters))

    if 'languages' in parameters.keys():
        return jsonify(languages=dbo.run_languages_query(parameters))

    return jsonify(corpora=dbo.get_corpora(parameters))
